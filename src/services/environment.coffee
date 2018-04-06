_includes = require 'lodash/includes'

class Environment
  isMobile: ({userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    ///
      Mobile
    | iP(hone|od|ad)
    | Android
    | BlackBerry
    | IEMobile
    | Kindle
    | NetFront
    | Silk-Accelerated
    | (hpw|web)OS
    | Fennec
    | Minimo
    | Opera\ M(obi|ini)
    | Blazer
    | Dolfin
    | Dolphin
    | Skyfire
    | Zune
    ///.test userAgent

  isFacebook: ->
    window? and window.name.indexOf('canvas_fb') isnt -1

  isAndroid: ({userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    _includes userAgent, 'Android'

  isiOS: ({userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    Boolean userAgent.match /iP(hone|od|ad)/g

  isNativeApp: (gameKey, {userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    Boolean gameKey and
      _includes(userAgent?.toLowerCase(), " #{gameKey}/") or
        _includes(userAgent?.toLowerCase(), ' starfire/') # legacy

  isGroupApp: (groupAppKey, {userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    Boolean groupAppKey and
      _includes(userAgent?.toLowerCase(), " openfam/#{groupAppKey}/")

  isGameChromeApp: (gameKey, {userAgent}) ->
    userAgent ?= navigator?.userAgent
    Boolean gameKey and
      _includes userAgent?.toLowerCase(), "chrome/#{gameKey}/"

  getAppVersion: (gameKey, {userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    regex = new RegExp("(#{gameKey}|starfire)\/(?:[a-zA-Z0-9]+/)?([0-9\.]+)")
    matches = userAgent.match(regex)
    matches?[2]

  isClayApp: ({userAgent} = {}) ->
    userAgent ?= navigator?.userAgent
    _includes userAgent?.toLowerCase(), 'clay/'

  isKikEnabled: ->
    Boolean window?.kik?.enabled

  getPlatform: ({gameKey, userAgent} = {}) =>
    userAgent ?= navigator?.userAgent

    if @isFacebook() then 'facebook'
    else if @isKikEnabled() then 'kik'
    else if @isGameChromeApp(gameKey, {userAgent}) then 'game_chrome_app'
    else if @isNativeApp(gameKey, {userAgent}) then 'game_app'
    else if @isClayApp({userAgent}) then 'clay_app'
    else 'web'

module.exports = new Environment()
