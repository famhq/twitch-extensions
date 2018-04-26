Exoid = require 'exoid'
request = require 'clay-request'
_isEmpty = require 'lodash/isEmpty'
_isPlainObject = require 'lodash/isPlainObject'
_defaults = require 'lodash/defaults'
_merge = require 'lodash/merge'
_pick = require 'lodash/pick'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/take'

Auth = require '../../../fam/src/models/auth'
Cookie = require '../../../fam/src/models/cookie'
Group = require '../../../fam/src/models/group'
GroupUser = require '../../../fam/src/models/group_user'
EarnAction = require '../../../fam/src/models/earn_action'
EarnAlert = require '../../../fam/src/models/earn_alert'
GroupRole = require '../../../fam/src/models/group_role'
Language = require './language'
Player = require '../../../fam/src/models/player'
Poll = require './poll'
TwitchSignInOverlay = require './twitch_sign_in_overlay'
Time = require '../../../fam/src/models/time'
User = require '../../../fam/src/models/user'
UserItem = require '../../../fam/src/models/user_item'
Window = require '../../../fam/src/models/window'

config = require '../config'

SERIALIZATION_KEY = 'MODEL'
SERIALIZATION_EXPIRE_TIME_MS = 1000 * 10 # 10 seconds

module.exports = class Model
  constructor: (options) ->
    {serverHeaders, io, @portal, language,
      initialCookies, setCookie, host} = options
    serverHeaders ?= {}

    cache = window?[SERIALIZATION_KEY] or {}
    window?[SERIALIZATION_KEY] = null
    # maybe this means less memory used for long caches?
    document?.querySelector('.model')?.innerHTML = ''

    # isExpired = if serialization.expires?
    #   # Because of potential clock skew we check around the value
    #   delta = Math.abs(Date.now() - serialization.expires)
    #   delta > SERIALIZATION_EXPIRE_TIME_MS
    # else
    #   true
    # cache = if isExpired then {} else serialization
    @isFromCache = not _isEmpty cache

    userAgent = serverHeaders['user-agent'] or navigator?.userAgent

    ioEmit = (event, opts) =>
      accessToken = @cookie.get 'accessToken'
      io.emit event, _defaults {accessToken, userAgent}, opts

    proxy = (url, opts) ->
      accessToken.take(1).toPromise()
      .then (accessToken) ->
        proxyHeaders =  _pick serverHeaders, [
          'cookie'
          'user-agent'
          'accept-language'
          'x-forwarded-for'
        ]
        request url, _merge {
          qs: if accessToken? then {accessToken} else {}
          headers: if _isPlainObject opts?.body
            _merge {
              # Avoid CORS preflight
              'Content-Type': 'text/plain'
            }, proxyHeaders
          else
            proxyHeaders
        }, opts

    @exoid = new Exoid
      ioEmit: ioEmit
      io: io
      cache: cache.exoid
      isServerSide: not window?

    pushToken = new RxBehaviorSubject null

    @cookie = new Cookie {initialCookies, setCookie, host}
    @l = new Language {language, @cookie}

    @auth = new Auth {@exoid, @cookie, pushToken, @l, userAgent, @portal}
    @user = new User {@auth, proxy, @exoid, @cookie, @l}
    @userItem = new UserItem {@auth}
    @player = new Player {@auth}
    @poll = new Poll {@auth}
    @earnAction = new EarnAction {@auth}
    @earnAlert = new EarnAlert()
    @group = new Group {@auth}
    @groupUser = new GroupUser {@auth}
    @groupRole = new GroupRole {@auth}
    @signInDialog = new TwitchSignInOverlay()
    @time = new Time({@auth})
    @portal?.setModels {
      @user, @player
    }
    @window = new Window {@cookie}

  wasCached: => @isFromCache

  dispose: =>
    @time.dispose()
    @exoid.disposeAll()

  getSerializationStream: =>
    @exoid.getCacheStream()
    .map (exoidCache) ->
      string = JSON.stringify({
        exoid: exoidCache
        # problem with this is clock skew
        # expires: Date.now() + SERIALIZATION_EXPIRE_TIME_MS
      }).replace /<\/script/gi, '<\\/script'
      "window['#{SERIALIZATION_KEY}']=#{string};"
