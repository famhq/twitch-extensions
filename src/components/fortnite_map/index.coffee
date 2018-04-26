z = require 'zorium'
_map = require 'lodash/map'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable

HeatMapWidget = require '../heat_map_widget'
Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class FortniteMap
  constructor: ({@model, group, requests}) ->
    @afterMountObs = new RxBehaviorSubject null
    windowSizeAndAfterMountObs = RxObservable.combineLatest(
      @model.window.getSize()
      @afterMountObs
      (vals...) -> vals
    )
    @dimensions = windowSizeAndAfterMountObs
    .map ([windowSize, afterMountObs]) =>
      boundingRect = @$$el?.getBoundingClientRect()
      width = boundingRect?.width or windowSize.width
      height = boundingRect?.height or windowSize.height
      size = Math.min width, height
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

  afterMount: (@$$el) =>
    @votes.next @poll.switchMap (poll) =>
      unless poll
        return

      @$heatMap.setMax poll.data?.heatMapMax

      @afterMountObs.next null

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
    {me, dimensions, votes, poll, path, myPin, group} = @state.getValue()

    meGroupUser = group?.meGroupUser

    pinSize = parseInt(dimensions?.width / 30)

    hasResetPermission = @model.groupUser.hasPermission {
      me, meGroupUser, permissions: ['deleteMessage']
    }

    z '.z-fortnite-map',
      z '.map', {
        onclick: (e) =>
          offsetTop = e.target.getBoundingClientRect().y
          offsetLeft = e.target.getBoundingClientRect().x
          x = ((e.clientX or e.touches?[0]?.clientX) - offsetLeft) /
                dimensions?.width
          y = ((e.clientY or e.touches?[0]?.clientY) - offsetTop) /
                dimensions?.height
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
        # FIXME: make this actually secure on backend...
        if hasResetPermission
          z '.reset-icon',
            z @$refreshIcon,
              icon: 'refresh'
              color: colors.$white
              onclick: (e) =>
                e?.stopPropagation()
                @model.poll.resetById poll.id
