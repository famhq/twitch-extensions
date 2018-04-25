z = require 'zorium'

config = require '../../config'
PrimaryButton = require '../../../../fam/src/components/primary_button'

if window?
  require './index.styl'

module.exports = class Earn
  constructor: ({@model, @router} = {}) ->
    @$button = new PrimaryButton()
    @state = z.state {
      me: @model.user.getMe()
    }

  render: =>
    {me} = @state.getValue()

    z '.z-earn',
      'earn'
      me?.username
      z @$button,
        text: 'go'
        onclick: =>
          @model.twitchSignInOverlay.openIfGuest me
          .then =>
            console.log 'in'
