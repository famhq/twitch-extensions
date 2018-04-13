express = require 'express'
_every = require 'lodash/every'
_values = require 'lodash/values'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
compress = require 'compression'
log = require 'loga'
helmet = require 'helmet'
z = require 'zorium'
Promise = require 'bluebird'
request = require 'clay-request'
cookieParser = require 'cookie-parser'
fs = require 'fs'
socketIO = require 'socket.io-client'
HttpHash = require 'http-hash'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/do'
require 'rxjs/add/operator/take'
require 'rxjs/add/operator/toPromise'
require 'rxjs/add/operator/publishReplay'
require 'rxjs/add/operator/concat'

config = require './src/config'
gulpPaths = require './gulp_paths'
App = require './src/app'
Model = require './src/models'
RouterService = require './src/services/router'

MIN_TIME_REQUIRED_FOR_HSTS_GOOGLE_PRELOAD_MS = 10886400000 # 18 weeks
HEALTHCHECK_TIMEOUT = 200
RENDER_TO_STRING_TIMEOUT_MS = 1200
BOT_RENDER_TO_STRING_TIMEOUT_MS = 4500

styles = if config.ENV is config.ENVS.PROD
  fs.readFileSync gulpPaths.dist + '/bundle.css', 'utf-8'
else
  null

app = express()
app.use compress()

# CSP is disabled because kik lacks support
# frameguard header is disabled because Native app frames page
app.disable 'x-powered-by'
app.use helmet.xssFilter()
app.use helmet.hsts
  # https://hstspreload.appspot.com/
  maxAge: MIN_TIME_REQUIRED_FOR_HSTS_GOOGLE_PRELOAD_MS
  includeSubDomains: true # include in Google Chrome
  preload: true # include in Google Chrome
  force: true
app.use helmet.noSniff()
app.use cookieParser()

app.use '/healthcheck', (req, res, next) ->
  Promise.all [
    Promise.cast(request(config.API_URL + '/ping'))
      .timeout HEALTHCHECK_TIMEOUT
      .reflect()
  ]
  .spread (api) ->
    result =
      api: api.isFulfilled()

    isHealthy = _every _values result
    if isHealthy
      res.json {healthy: isHealthy}
    else
      res.status(500).json _defaults {healthy: isHealthy}, result
  .catch next

app.use '/ping', (req, res) ->
  res.send 'pong'

app.use '/setCookie', (req, res) ->
  res.statusCode = 302
  res.cookie 'first_cookie', '1', {maxAge: 3600 * 24 * 365 * 10}
  res.setHeader 'Location', decodeURIComponent req.query?.redirect_url
  res.end()

if config.ENV is config.ENVS.PROD
then app.use express.static(gulpPaths.dist, {maxAge: '4h'})
else app.use express.static(gulpPaths.build, {maxAge: '4h'})

stats = JSON.parse \
  fs.readFileSync gulpPaths.dist + '/stats.json', 'utf-8'

app.use (req, res, next) ->
  # migrate to openfam.com
  # check if native app
  userAgent = req.headers['user-agent']
  host = req.headers.host
  accessToken = req.query.accessToken
  isNativeApp = userAgent?.indexOf('starfire') isnt -1 or
                  userAgent?.indexOf('openfam') isnt -1
  isiOS = /(iPad|iPhone|iPod)/g.test(userAgent)
  isiOSApp = isNativeApp and isiOS
  isBot = /bot|crawler|spider|crawling/i.test(userAgent)
  isLegacyHost = host.indexOf('starfi.re') isnt -1 or
                  host.indexOf('redtritium.com') isnt -1 or
                  host.indexOf('starfire.games') isnt -1

  hasSent = false

  cookieSubject = new RxBehaviorSubject req.cookies

  io = socketIO config.API_HOST, {
    path: (config.API_PATH or '') + '/socket.io'
    timeout: 5000
    transports: ['websocket']
  }
  fullLanguage = req.headers?['accept-language']
  language = req.query?.lang or
    req.cookies?['language'] or
    fullLanguage?.substr(0, 2)
  unless language in config.LANGUAGES
    language = 'en'
  model = new Model {
    cookieSubject, io, serverHeaders: req.headers, language
  }
  router = new RouterService {
    router: null
    model: model
  }
  requests = new RxBehaviorSubject(req)

  setCookies = (currentCookies) ->
    (cookies) ->
      _map cookies, (value, key) ->
        if currentCookies[key] isnt value and not hasSent
          res.cookie(key, value, model.cookie.getCookieOpts(host, key))
      currentCookies = cookies
  disposable = cookieSubject.do(setCookies(req.cookies)).subscribe()

  # for client to access
  model.cookie.set(
    'ip'
    req.headers?['x-forwarded-for'] or req.connection.remoteAddress
  )

  if config.ENV is config.ENVS.PROD
    scriptsCdnUrl = config.SCRIPTS_CDN_URL
    bundlePath = "#{scriptsCdnUrl}/bundle_#{stats.hash}_#{language}.js"
    bundleCssPath = "/bundle.css?#{stats.time}"
  else
    bundlePath = null
    bundleCssPath = null

  serverData = {req, res, bundlePath, bundleCssPath, styles}
  userAgent = req.headers?['user-agent']
  isFacebookCrawler = userAgent?.indexOf('facebookexternalhit') isnt -1 or
      userAgent?.indexOf('Facebot') isnt -1
  isOtherBot = userAgent?.indexOf('bot') isnt -1
  isCrawler = isFacebookCrawler or isOtherBot
  start = Date.now()
  z.renderToString new App({requests, model, serverData, router, isCrawler}), {
    timeout: if isCrawler \
             then BOT_RENDER_TO_STRING_TIMEOUT_MS
             else RENDER_TO_STRING_TIMEOUT_MS
  }
  .then (html) ->
    io.disconnect()
    model.dispose()
    disposable.unsubscribe()
    disposable = null
    hasSent = true
    # TODO: not sure why, but some paths (eg /g/clashroyale/somerandompage)
    # send back before head exists
    if html.indexOf('<head>') is -1
      res.redirect 302, '/'
    else
      res.send '<!DOCTYPE html>' + html
  .catch (err) ->
    io.disconnect()
    model.dispose()
    disposable?.unsubscribe()
    log.error err
    if err.html
      hasSent = true
      if err.html.indexOf('<head>') is -1
        res.redirect 302, '/'
      else
        res.send '<!DOCTYPE html>' + err.html
    else
      next err

module.exports = app