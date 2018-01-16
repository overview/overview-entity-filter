const HtmlWebpackPlugin = require('html-webpack-plugin')
const ExtractTextPlugin = require('extract-text-webpack-plugin')
const UglifyJsPlugin = require('uglifyjs-webpack-plugin')

const extractLess = new ExtractTextPlugin({
  filename: '[name].[contenthash].css',
})

module.exports = {
  context: __dirname + '/app',
  devtool: 'source-map',
  entry: './show.coffee',
  output: {
    path: __dirname + '/dist',
    filename: 'show.[chunkhash].js',
  },
  resolve: {
    extensions: [ '.js', '.coffee' ],
  },
  module: {
    rules: [
      {
        test: /\.coffee$/,
        use: [
          {
            loader: 'coffee-loader',
            options: { sourceMap: true },
          },
        ],
      },
      {
        test: /\.(woff2|png)$/,
        use: 'base64-inline-loader',
      },
      {
        test: /\.(css|less)$/,
        use: extractLess.extract({
          use: [
            { loader: 'css-loader', },
            { loader: 'less-loader', },
          ],
          fallback: 'style-loader',
        }),
      },
    ],
  },
  plugins: [
    extractLess,
    new HtmlWebpackPlugin({
      title: 'Entity Filter',
      filename: 'show',
      template: 'show.html',
      cache: false,
    }),
    new UglifyJsPlugin({
      uglifyOptions: {
        compress: {
          ecma: 6,
        },
        output: {
          ecma: 6,
        },
      },
    }),
  ]
}
