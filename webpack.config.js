const HtmlWebpackPlugin = require('html-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')

module.exports = {
  context: __dirname + '/app',
  devtool: 'source-map',
  entry: './show.js',
  watchOptions: {
    ignored: /node_modules/,
  },
  output: {
    path: __dirname + '/dist',
    filename: 'show.[chunkhash].js',
  },
  module: {
    rules: [
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
      title: 'Overview Entity Filter',
      filename: 'show',
      meta: {charset: 'utf-8'},
    }),
  ]
}
