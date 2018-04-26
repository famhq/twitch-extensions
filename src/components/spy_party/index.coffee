z = require 'zorium'
_map = require 'lodash/map'
_groupBy = require 'lodash/groupBy'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
left / right buttons
in-between them have all pictures, each clickable
border around one you clicked
###

CHARACTERS = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
              'n', 'o', 'p', 'q', 'r', 's', 't', 'u']

module.exports = class SpyParty
  constructor: ({@model, group, requests}) ->
    @dimensions = @model.window.getSize().map (windowSize) ->
      size = Math.min windowSize.width, windowSize.height
      {
        width: size
        height: size
      }

    @$leftIcon = new Icon()
    @$rightIcon = new Icon()
    @$slideIcon = new Icon()
    @votes = new RxReplaySubject 1

    @poll = group.switchMap (group) =>
      @model.poll.getAllByGroupId group.id
      .map (polls) ->
        polls[0]

    path = requests.map ({req}) ->
      req?.path

    @state = z.state {
      me: @model.user.getMe()
      dimensions: @dimensions
      poll: @poll
      group: group
      votes: @votes.switch()
      isOpen: false
      path: path
      selectedCharacter: null
    }

  afterMount: =>
    @votes.next @poll.switchMap (poll) =>
      unless poll
        return RxObservable.of null
      @model.poll.getAllVotesById poll.id

  render: =>
    {me, dimensions, votes, poll, path, selectedCharacter, isOpen} = @state.getValue()

    # FIXME: do this on backend
    voteCount = votes?.length
    characterVotes = _groupBy votes, 'value'

    # FIXME: get rid of grid, scale using dimensions

    z '.z-spy-party', {
      className: z.classKebab {isOpen}
    },
      z '.slide', {
        onclick: =>
          @state.set isOpen: not isOpen
      },
        z '.icon',
          z @$slideIcon,
            icon: if isOpen then 'caret-right' else 'caret-left'
            size: '36px'
            isTouchTarget: false
            color: colors.$white
      z '.flex',
        z '.left',
          z @$leftIcon,
            icon: 'caret-left'
            size: '60px'
            color: colors.$red500
        z '.characters',
          z '.g-grid',
            z '.g-cols',
              _map CHARACTERS, (character) =>
                isSelected = character is selectedCharacter
                voteRatio = if characterVotes[character] \
                        then (characterVotes[character].length / voteCount)
                        else 0
                z '.g-col.g-xs-3.g-md-2',
                  z '.character', {
                    className: z.classKebab {isSelected}
                    style:
                      backgroundImage:
                        "url(#{config.CDN_URL}/spy_party/#{character}.png)"
                    onclick: =>
                      @state.set selectedCharacter: character
                      @model.poll.voteById poll.id, {value: character}
                  },
                    z '.selection-bar',
                      style:
                        transform: "scaleY(#{voteRatio})"
                        webkitTransform: "scaleY(#{voteRatio})"
        z '.right',
          z @$rightIcon,
            icon: 'caret-right'
            size: '60px'
            color: colors.$red500
      z '.shoot-button',
        'SHOOT'
