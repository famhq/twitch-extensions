z = require 'zorium'

CurrencyIcon = require '../currency_icon'
FormatService = require '../../services/format'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class AppBar
  constructor: ({@model, group}) ->
    itemKey = group.map (group) ->
      group.currency?.itemKey

    @$currencyIcon = new CurrencyIcon {
      itemKey: itemKey
    }

    @state = z.state
      me: @model.user.getMe()
      group: group
      currencyItem: itemKey.switchMap (itemKey) =>
        if itemKey
          @model.userItem.getByItemKey itemKey
        else
          RxObservable.of null

  getHeight: =>
    @model.window.getAppBarHeight()

  render: (options) ->
    {$topLeftButton, $topRightButton, title, bgColor, color, isFlat,
      style, isFullWidth} = options

    {group, currencyItem} = @state.getValue()

    color ?= colors.$header500Text
    bgColor ?= colors.$header500

    if group?.currency
      $topRightButton ?=
        z '.group-currency',
          FormatService.number currencyItem?.count or 0
          z '.icon',
            z @$currencyIcon, {size: '20px'}


    z 'header.z-app-bar', {
      className: z.classKebab {isFlat}
    },
      z '.bar', {
        style:
          backgroundColor: bgColor
      },
        z '.wrapper', {
          className: z.classKebab {
            gGrid: not isFullWidth
          }
        },
          z '.top',
            if $topLeftButton
              z '.top-left-button', {
                style:
                  color: color
              },
                $topLeftButton
            z '.title', {
              style:
                color: color
            }, title
            z '.top-right-button', {
              style:
                color: color
            },
              $topRightButton
