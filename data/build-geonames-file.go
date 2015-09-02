package main

/*
 * Parses the `allCountries.zip` file from
 * http://download.geonames.org/export/dump/ and spits out preprocessed,
 * gzipped data files formatted like this:
 *
 * search key\tCanonical Name\n
 * search key 2\tCanincal Name 2
 *
 * Usage:
 *
 * mkdir -p ~/.gocode
 * export GOPATH=~/.gocode
 * go run ./build-geonames-file.go countries # or "cities" or "political"
 */

import (
    "archive/zip"
    "bufio"
    "bytes"
    "compress/gzip"
    "fmt"
    "io"
    "os"
    "regexp"
    "sort"
    "strings"

    "golang.org/x/text/unicode/norm"
)

var normalizePunctuationRegex = regexp.MustCompile("[- \\(\\)!`\"\\\\/&{}~]+")
var urlRegex = regexp.MustCompile("^https?:")
var truncateRegex = regexp.MustCompile("^([^ ]+ ){0,4}[^ ]+")
var numberRegex = regexp.MustCompile("^[-\\d\\._]+$")

type RowFilterFunc func(cells [][]byte) bool

func Normalize(s string) string {
    noPunctuation := normalizePunctuationRegex.ReplaceAllLiteralString(s, " ")
    trimmed := strings.TrimSpace(noPunctuation)
    truncated := truncateRegex.FindString(trimmed)
    return strings.ToLower(truncated)
}

func RemoveDuplicates(strings []string) []string {
    ret := []string{}

    lastString := ""

    for _, s := range strings {
        if s != lastString {
            ret = append(ret, s)
            lastString = s
        }
    }

    return ret
}

func ProcessGeonamesFile(r io.Reader, rowFilterFunc RowFilterFunc) []string {
    var tab = []byte("\t")
    var comma = []byte(",")

    var ret []string = make([]string, 0)

    scanner := bufio.NewScanner(r)
    for scanner.Scan() {
        line := scanner.Bytes()
        cells := bytes.Split(line, tab)

        if !rowFilterFunc(cells) {
            // skip this geographical feature
            continue
        }

        if len(cells[1]) == 0 {
            // this feature has no name
            continue
        }

        name := string(cells[1])

        ret = append(ret, Normalize(name) + "\t" + name)

        alts := bytes.Split(cells[3], comma)

        for _, alt := range alts {
            if len(alt) == 0 { continue } // there are no alternate names
            if urlRegex.Match(alt) { continue }
            if numberRegex.Match(alt) { continue }

            ret = append(ret, Normalize(string(alt)) + "\t" + name)
        }
    }

    return ret
}

func main() {
    // Open archive
    r, err := zip.OpenReader("./allCountries.zip")
    if err != nil { panic(err) }
    defer r.Close()

    if len(os.Args) != 2 || (os.Args[1] != "countries" && os.Args[1] != "cities" && os.Args[1] != "political") {
      panic(fmt.Sprintf("Usage: %s countries|cities|political", os.Args[0]))
    }

    var rowFilterFunc RowFilterFunc

    switch os.Args[1] {
    case "countries":
      rowFilterFunc = func(cells [][]byte) bool {
        var featureCode = cells[7]
        return len(featureCode) >= 3 &&
          featureCode[0] == byte('P') &&
          featureCode[1] == byte('C') &&
          featureCode[2] == byte('L')
      }
    case "political":
      rowFilterFunc = func(cells [][]byte) bool {
        var featureClass = cells[6]
        return len(featureClass) == 1 &&
          featureClass[0] == byte('A')
      }
    case "cities":
      rowFilterFunc = func(cells [][]byte) bool {
        var featureClass = cells[6]
        var population = cells[14]
        return len(featureClass) == 1 &&
          featureClass[0] == byte('P') &&
          len(population) >= 5 // 5 digits = pop >= 10,000
      }
    }

    var outputLines []string = make([]string, 0)

    // Iterate over all files
    for _, f := range r.File {
        rc, err := f.Open()
        if err != nil { panic(err) }
        outputLines = append(outputLines, ProcessGeonamesFile(rc, rowFilterFunc)...)
        rc.Close()
    }

    sort.Strings(outputLines)
    uniq := RemoveDuplicates(outputLines)

    output := strings.Join(uniq, "\n")
    normalizedOutput := norm.NFKC.String(output)
    outputBytes := []byte(normalizedOutput)

    w, err := os.Create(fmt.Sprintf("geonames-%s.txt.gz", os.Args[1]))
    if err != nil { panic(err) }

    zw, err := gzip.NewWriterLevel(w, gzip.BestCompression)
    if err != nil { panic(err) }
    zw.Write(outputBytes)

    err = zw.Close()
    if err != nil { panic(err) }

    err = w.Close()
    if err != nil { panic(err) }
}
