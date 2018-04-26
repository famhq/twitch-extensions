z = require 'zorium'

config = require '../../config'
PrimaryButton = require '../../../../fam/src/components/primary_button'

if window?
  require './index.styl'

module.exports = class Config
  constructor: ({@model, @router} = {}) ->
    @$button = new PrimaryButton()
    @state = z.state {
      me: @model.user.getMe()
    }

  render: =>
    {me} = @state.getValue()

    z '.z-config',
      'config'
      z @$button,
        text: 'connect'
        onclick: => null
