z = require 'zorium'

FortniteMap = require '../../components/fortnite_map'
AppBar = require '../../components/app_bar'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ToolsPage
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    @$fortniteMap = new FortniteMap {@model, group, requests}

    @$appBar = new AppBar {@model, @router, group}

    @state = z.state
      me: @model.user.getMe()
      windowSize: @model.window.getSize()

  render: =>
    {me, windowSize} = @state.getValue()

    z '.p-tools', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar,
        title: @model.l.get 'general.tools'
      @$fortniteMap
      @$bottomBar
