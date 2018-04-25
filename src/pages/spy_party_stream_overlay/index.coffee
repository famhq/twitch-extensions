z = require 'zorium'

SpyParty = require '../../components/spy_party'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SpyPartyStreamOverlayPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @$spyParty = new SpyParty {@model, group, requests}

    @state = z.state
      me: @model.user.getMe()
      windowSize: @model.window.getSize()

  render: =>
    {me, windowSize} = @state.getValue()

    z '.p-spy-party-stream-overlay', {
      style:
        height: "#{windowSize.height}px"
    },
      @$spyParty
