z = require 'zorium'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class TwitchSignInOverlay
  constructor: ({@model, @router}) ->
    null

  render: =>
    z '.z-twitch-sign-in-overlay',
      z '.content',
        z '.instructions',
          z '.title',
            @model.l.get 'twitchSignInOverlay.title'
          z '.text',
            @model.l.get 'twitchSignInOverlay.text1'
            z '.twitch-permissions-icon'
          z '.text',
            @model.l.get 'twitchSignInOverlay.text2'
        z '.arrow'
