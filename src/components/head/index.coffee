z = require 'zorium'
Environment = require '../../services/environment'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_merge = require 'lodash/merge'
_map = require 'lodash/map'
_mapValues = require 'lodash/mapValues'
_defaults = require 'lodash/defaults'

config = require '../../config'
colors = require '../../colors'
rubikCss = require './rubik'

DEFAULT_IMAGE = 'https://cdn.wtf/d/images/fam/web_icon_256.png'

module.exports = class Head
  constructor: ({@model, requests, serverData, group}) ->
    route = requests.map ({route}) -> route
    requestsAndLanguage = RxObservable.combineLatest(
      requests, @model.l.getLanguage(), (vals...) -> vals
    )

    @lastGroupId = null

    @state = z.state
      serverData: serverData
      route: route
      group: group
      routeKey: route.map (route) =>
        if route?.src
          routeKey = @model.l.getRouteKeyByValue route.src
      modelSerialization: unless window?
        @model.getSerializationStream()
      cssVariables: group?.map (group) =>
        groupKey = group?.key
        if groupKey and groupKey.indexOf('clashroyale') isnt -1
          groupKey = 'clashroyale'
        if groupKey and groupKey.indexOf('fortnite') isnt -1
          groupKey = 'fortnite'
        if groupKey and groupKey.indexOf('brawlstars') isnt -1
          groupKey = 'brawlstars'

        cssColors = _defaults colors[groupKey], colors.default
        cssColors['--drawer-header-500'] ?= cssColors['--primary-500']
        cssColors['--drawer-header-500-text'] ?= cssColors['--primary-500-text']
        cssVariables = _map(cssColors, (value, key) ->
          "#{key}:#{value}"
        ).join ';'

        if @lastGroupId isnt group.id
          newStatusBarColor = cssColors['--status-bar-500'] or
                              cssColors['--primary-900']
          @model.portal?.call 'statusBar.setBackgroundColor', {
            color: newStatusBarColor
          }
          @lastGroupId = group.id
          @model.cookie.set "group_#{group.id}_lastVisit", Date.now()
          if cssVariables
            @model.cookie.set 'cachedCssVariables', cssVariables

        cssVariables

  render: =>
    {serverData, route, routeKey, group,
      modelSerialization, cssVariables} = @state.getValue()

    gaId = switch group?.key
      when 'fortnitees'
      then 'UA-27992080-33'
      else 'UA-27992080-30'

    paths = _mapValues @model.l.getAllPathsByRouteKey(routeKey), (path) ->
      pathVars = path.match /:([a-zA-Z0-9-]+)/g
      _map pathVars, (pathVar) ->
        path = path.replace pathVar, route.params[pathVar.substring(1)]
      path

    userAgent = navigator?.userAgent or serverData?.req?.headers?['user-agent']

    isInliningSource = config.ENV is config.ENVS.PROD
    webpackDevUrl = config.WEBPACK_DEV_URL
    isNative = Environment.isNativeApp(config.GAME_KEY, {userAgent})
    host = serverData?.req?.headers.host or window?.location?.host

    z 'head',
      z 'title', ''
      # mobile
      z 'meta',
        name: 'viewport'
        content: 'initial-scale=1.0, width=device-width, minimum-scale=1.0,
                  maximum-scale=1.0, user-scalable=0, minimal-ui,
                  viewport-fit=cover'

      z 'meta',
        'http-equiv': 'Content-Security-Policy'
        content: "default-src 'self' file://* *; style-src 'self'" +
          " 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'"

      # styles
      z 'style.css-variables',
        key: 'css-variables'
        innerHTML:
          ":root {#{cssVariables or @model.cookie.get 'cachedCssVariables'}}"

      z 'style.rubik',
        innerHTML: rubikCss

      # scripts
      z 'script',
        src: 'https://extension-files.twitch.tv/helper/v1/twitch-ext.min.js'
      z 'script.bundle',
        async: true
        src: if isInliningSource then 'bundle.js' \
             else "#{webpackDevUrl}/bundle.js"

      if isInliningSource
        z 'link',
          rel: 'stylesheet'
          type: 'text/css'
          href: 'bundle.css'
