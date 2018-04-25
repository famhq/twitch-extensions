z = require 'zorium'

Earn = require '../../components/earn'
AppBar = require '../../components/app_bar'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EarnPage
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    @$earn = new Earn {@model, group, requests}

    @$appBar = new AppBar {@model, @router}

    @state = z.state
      me: @model.user.getMe()
      windowSize: @model.window.getSize()

  render: =>
    {me, windowSize} = @state.getValue()

    z '.p-earn', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar,
        title: @model.l.get 'general.earn'
      @$earn
      @$bottomBar
