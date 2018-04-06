z = require 'zorium'
HttpHash = require 'http-hash'
_forEach = require 'lodash/forEach'
_map = require 'lodash/map'
_values = require 'lodash/values'
_flatten = require 'lodash/flatten'
_defaults = require 'lodash/defaults'
Environment = require './services/environment'
isUuid = require 'isuuid'
RxObservable = require('rxjs/Observable').Observable
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/filter'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/publishReplay'

Head = require './components/head'
config = require './config'
colors = require './colors'

Pages =
  HomePage: require './pages/home'

TIME_UNTIL_ADD_TO_HOME_PROMPT_MS = 90000 # 1.5 min

module.exports = class App
  constructor: (options) ->
    {requests, @serverData, @model, @router, isOffline, @isCrawler} = options
    @$cachedPages = []
    routes = @model.window.getBreakpoint().map @getRoutes
            .publishReplay(1).refCount()

    userAgent = navigator?.userAgent or
                  requests.getValue().headers?['user-agent']

    requestsAndRoutes = RxObservable.combineLatest(
      requests, routes, (vals...) -> vals
    )

    isFirstRequest = true
    @requests = requestsAndRoutes.map ([req, routes]) ->
      route = routes.get req.path
      $page = route.handler?()
      isFirstRequest = false
      {req, route, $page: $page}
    .publishReplay(1).refCount()

    requestsAndLanguage = RxObservable.combineLatest(
      @requests, @model.l.getLanguage(), (vals...) -> vals
    )

    @group = requestsAndLanguage.switchMap ([{route}, language]) =>
      # TODO: use channel id
      @model.group.getByKey 'nickatnyte'
    .publishReplay(1).refCount()

    @$head = new Head({
      @model
      @requests
      @serverData
      @group
    })

    me = @model.user.getMe()

    $backupPage = if @serverData?
      userAgent = @serverData.req.headers?['user-agent']
      if Environment.isNativeApp config.GAME_KEY, {userAgent}
        serverPath = @model.cookie.get('lastPath') or @serverData.req.path
      else
        serverPath = @serverData.req.path
      @getRoutes().get(serverPath).handler?()
    else
      null

    @state = z.state {
      me: me
      isOffline: isOffline
      request: @requests
      $backupPage: $backupPage
    }

  getRoutes: (breakpoint) =>
    # can have breakpoint (mobile/desktop) specific routes
    routes = new HttpHash()
    languages = @model.l.getAllUrlLanguages()

    route = (paths, pageKey) =>
      Page = Pages[pageKey]
      if typeof paths is 'string'
        paths = [paths]

      paths = _flatten paths

      _map paths, (path) =>
        routes.set path, =>
          unless @$cachedPages[pageKey]
            @$cachedPages[pageKey] = new Page({
              @model
              @router
              @serverData
              @group
              requests: @requests.filter ({$page}) ->
                $page instanceof Page
            })
          return @$cachedPages[pageKey]

    route ['/*'], 'HomePage'
    routes

  render: =>
    {request, me, isOffline, $backupPage} = @state.getValue()

    userAgent = request?.req?.headers?['user-agent'] or
      navigator?.userAgent or ''
    isIos = /iPad|iPhone|iPod/.test userAgent
    defaultInstallMessage = @model.l.get 'app.defaultInstallMessage'

    $page = request?.$page or $backupPage

    z 'html',
      z @$head, {meta: $page?.getMeta?()}
      z 'body',
        z '#zorium-root', {
          className: z.classKebab {isIos}
        },
          z '.z-root',
            z '.page',
              # show page before me has loaded
              if request?.$page
                request.$page

            # used in color.coffee to detect support
            z '#css-variable-test',
              style:
                display: 'none'
                backgroundColor: 'var(--test-color)'
