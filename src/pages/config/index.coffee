z = require 'zorium'

Config = require '../../components/config'
AppBar = require '../../components/app_bar'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ConfigPage
  constructor: ({@model, @router, requests, serverData, group}) ->
    @$config = new Config {@model, group, requests}

    @$appBar = new AppBar {@model, @router}

    @state = z.state
      me: @model.user.getMe()
      windowSize: @model.window.getSize()

  render: =>
    {me, windowSize} = @state.getValue()

    z '.p-config', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar,
        title: @model.l.get 'general.config'
      @$config
