express = require 'express'
dust = require 'dustjs-linkedin'
fs = require 'fs'

config = require './src/config'

indexTpl = dust.compile fs.readFileSync('./src/index.dust', 'utf-8'), 'index'
dust.loadSource indexTpl

app = express()

app.use (req, res, next) ->
  dust.render 'index', {
    webpack: config.ENV is config.ENVS.DEV
    webpackDevHostname: config.WEBPACK_DEV_URL
  }, (err, html) ->
    res.send html

module.exports = app
