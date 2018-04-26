z = require 'zorium'

config = require '../../config'
PrimaryButton = require '../../../../fam/src/components/primary_button'
EarnCurrency = require '../../../../fam/src/components/group_earn_currency'

if window?
  require './index.styl'

module.exports = class Earn
  constructor: ({@model, @router, group} = {}) ->
    @$button = new PrimaryButton()
    @$earnCurrency = new EarnCurrency {@model, @router, group}
    @state = z.state {
      me: @model.user.getMe()
    }

  render: =>
    {me} = @state.getValue()

    z '.z-earn',
      z @$earnCurrency
