z = require 'zorium'

FortniteMap = require '../../components/fortnite_map'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class HomePage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @$fortniteMap = new FortniteMap {@model, group, requests}

    @state = z.state
      me: @model.user.getMe()
      windowSize: @model.window.getSize()

  getMeta: ->
    meta:
      canonical: "https://#{config.HOST}"

  render: =>
    {me, windowSize} = @state.getValue()

    z '.p-home', {
      style:
        height: "#{windowSize.height}px"
    },
      @$fortniteMap
