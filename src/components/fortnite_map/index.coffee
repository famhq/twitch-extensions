z = require 'zorium'
_map = require 'lodash/map'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable

HeatMapWidget = require '../heat_map_widget'
Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class FortniteMap
  constructor: ({@model, group, requests}) ->
    @dimensions = @model.window.getSize().map (windowSize) ->
      size = Math.min windowSize.width, windowSize.height
      {
        width: size
        height: size
      }

    @$heatMap = new HeatMapWidget {@dimensions}
    @$refreshIcon = new Icon()
    @$pinIcon = new Icon()
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
      myPin: null
      path: path
    }

  afterMount: =>
    @votes.next @poll.switchMap (poll) =>
      unless poll
        return

      @$heatMap.setMax poll.data?.heatMapMax

      votes = @model.poll.getAllVotesById poll.id
      dimensionsAndVotes = RxObservable.combineLatest(
        @dimensions
        votes
      )

      dimensionsAndVotes
      .map ([dimensions, votes]) =>
        @$heatMap.setDataPoints _map(votes, ({value}) ->
          [
            value[0] * dimensions?.width
            value[1] * dimensions?.height
            value[2]
          ]
        )
        votes

  render: =>
    {me, dimensions, votes, poll, path, myPin} = @state.getValue()

    pinSize = parseInt(dimensions?.width / 30)

    z '.z-fortnite-map',
      z '.map', {
        onclick: (e) =>
          x = (e.clientX or e.touches?[0]?.clientX) / dimensions?.width
          y = (e.clientY or e.touches?[0]?.clientY) / dimensions?.height
          @state.set myPin: [x, y]
          @model.poll.voteById poll.id, {value: [x, y, 1]}
        style:
          width: "#{dimensions?.width}px"
          height: "#{dimensions?.height}px"
      },
        z @$heatMap
        if myPin
          z '.pin', {
            style:
              left: "#{myPin[0] * dimensions?.width - pinSize / 2}px"
              top: "#{myPin[1] * dimensions?.height - pinSize / 1.1}px"
          },
            z @$pinIcon,
              icon: 'pin'
              isTouchTarget: false
              color: colors.$white
              size: "#{pinSize}px"
        # FIXME: make this actually secure...
        if path and path.indexOf('/live-config.html') isnt -1
          z '.reset-icon',
            # FIXME: polls need to be streamed so it updates for all
            z @$refreshIcon,
              icon: 'refresh'
              color: colors.$white
              onclick: (e) =>
                e?.stopPropagation()
                @model.poll.resetById poll.id
