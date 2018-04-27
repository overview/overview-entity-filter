const HtmlWebpackPlugin = require('html-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const UglifyJsPlugin = require('uglifyjs-webpack-plugin')

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
  mode: 'production',
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
        test: /\.(css|scss)$/,
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader',
          'sass-loader',
        ],
      },
    ],
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: '[name].[contenthash].css',
    }),
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
