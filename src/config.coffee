# process.env.* is replaced at run-time with * environment variable
# Note that simply env.* is not replaced, and thus suitible for private config

_map = require 'lodash/map'
_range = require 'lodash/range'
_merge = require 'lodash/merge'
assertNoneMissing = require 'assert-none-missing'

colors = require './colors'

# Don't let server environment variables leak into client code
serverEnv = process.env

HOST = process.env.FAM_HOST or '127.0.0.1'
HOSTNAME = HOST.split(':')[0]

API_URL =
  serverEnv.RADIOACTIVE_API_URL or # server
  process.env.PUBLIC_RADIOACTIVE_API_URL # client

DEV_USE_HTTPS = process.env.DEV_USE_HTTPS and process.env.DEV_USE_HTTPS isnt '0'

isUrl = API_URL.indexOf('/') isnt -1
if isUrl
  API_HOST_ARRAY = API_URL.split('/')
  API_HOST = API_HOST_ARRAY[0] + '//' + API_HOST_ARRAY[2]
  API_PATH = API_URL.replace API_HOST, ''
else
  API_HOST = API_URL
  API_PATH = ''
# All keys must have values at run-time (value may be null)
isomorphic =
  COMMUNITY_LANGUAGES: ['es', 'pt', 'pl']
  LANGUAGES: [
    'en', 'es', 'it', 'fr', 'zh', 'ja', 'ko', 'de', 'pt', 'pl'
    'ru', 'id', 'tl', 'tr'
  ]
  CDN_URL: 'https://cdn.wtf/d/images/fam'
  # d folder has longer cache
  SCRIPTS_CDN_URL: 'https://cdn.wtf/d/scripts/fam'
  USER_CDN_URL: 'https://cdn.wtf/images/fam'
  DEFAULT_IOS_APP_ID: '1160535565'
  IOS_APP_URL: 'https://itunes.apple.com/us/app/fam/id1160535565'
  DEFAULT_GOOGLE_PLAY_APP_ID: 'com.clay.redtritium'
  GOOGLE_PLAY_APP_URL:
    'https://play.google.com/store/apps/details?id=com.clay.redtritium'
  HOST: HOST
  GAME_KEY: 'openfam'
  API_URL: API_URL
  PUBLIC_API_URL: process.env.PUBLIC_RADIOACTIVE_API_URL
  API_HOST: API_HOST
  API_PATH: API_PATH
  VAPID_PUBLIC_KEY: process.env.RADIOACTIVE_VAPID_PUBLIC_KEY
  DEV_USE_HTTPS: DEV_USE_HTTPS
  AUTH_COOKIE: 'accessToken'
  ENV:
    serverEnv.NODE_ENV or
    process.env.NODE_ENV
  ENVS:
    DEV: 'development'
    PROD: 'production'
    TEST: 'test'

# Server only
# All keys must have values at run-time (value may be null)
PORT = 8080
WEBPACK_DEV_PORT = serverEnv.WEBPACK_DEV_PORT or parseInt(PORT) + 1
WEBPACK_DEV_PROTOCOL = if DEV_USE_HTTPS then 'https://' else 'http://'

server =
  PORT: PORT

  # Development
  WEBPACK_DEV_PORT: WEBPACK_DEV_PORT
  WEBPACK_DEV_PROTOCOL: WEBPACK_DEV_PROTOCOL
  WEBPACK_DEV_URL: serverEnv.WEBPACK_DEV_URL or
    "#{WEBPACK_DEV_PROTOCOL}#{HOSTNAME}:#{WEBPACK_DEV_PORT}"
  SELENIUM_TARGET_URL: serverEnv.SELENIUM_TARGET_URL or null
  REMOTE_SELENIUM: serverEnv.REMOTE_SELENIUM is '1'
  SELENIUM_BROWSER: serverEnv.SELENIUM_BROWSER or 'chrome'
  SAUCE_USERNAME: serverEnv.SAUCE_USERNAME or null
  SAUCE_ACCESS_KEY: serverEnv.SAUCE_ACCESS_KEY or null

assertNoneMissing isomorphic
if window?
  module.exports = isomorphic
else
  assertNoneMissing server
  module.exports = _merge isomorphic, server
