z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_find = require 'lodash/find'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'


module.exports = class BottomBar
  constructor: ({@model, @router, requests, group}) ->
    @state = z.state
      requests: requests
      group: group

  afterMount: (@$$el) => null

  hide: =>
    @$$el?.classList.add 'is-hidden'

  show: =>
    @$$el?.classList.remove 'is-hidden'

  render: ({isAbsolute} = {}) =>
    {requests, group} = @state.getValue()

    currentPath = requests?.req.path

    groupId = group?.key or group?.id or 'clashroyale'
    isLoaded = Boolean group

    # per-group menu:
    # profile, tools, home, forum, chat
    @menuItems = _filter [
      {
        # $icon: new CurrencyIcon {
        #   itemKey: group?.currency?.itemKey
        # }
        $icon: new Icon()
        icon: 'add-circle'
        route: '/earn'
        text: @model.l.get 'general.earn'
        isDefault: true
      }
      # {
      #   $icon: new Icon()
      #   icon: 'profile'
      #   route: '/spend'
      #   text: @model.l.get 'general.spend'
      # }
      {
        $icon: new Icon()
        icon: 'map'
        route: '/heatmap'
        text: @model.l.get 'bottomBar.heatmap'
      }
    ]

    z '.z-bottom-bar', {
      key: 'bottom-bar'
      className: z.classKebab {isLoaded, isAbsolute}
    },
      _map @menuItems, (menuItem, i) =>
        {$icon, icon, route, text, isDefault, hasNotification} = menuItem

        if isDefault
          isSelected = currentPath and (
            currentPath.indexOf('.html') isnt -1 or
            currentPath.indexOf(route) isnt -1
          )
        else
          isSelected = currentPath and currentPath.indexOf(route) isnt -1

        z 'a.menu-item', {
          attributes:
            tabindex: i
          className: z.classKebab {isSelected, hasNotification}
          href: route
          onclick: (e) =>
            e?.preventDefault()
            # without delay, browser will wait until the next render is complete
            # before showing ripple. seems better to start ripple animation
            # first
            setImmediate =>
              @router.goPath route
        },
          z '.icon',
            z $icon,
              icon: icon
              color: if isSelected then colors.$primary500 else colors.$tertiary900Text54
              isTouchTarget: false
              size: '24px'
          z '.text', text
