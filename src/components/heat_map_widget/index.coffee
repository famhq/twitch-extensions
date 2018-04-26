z = require 'zorium'

colors = require '../../colors'

if window?
  simpleheat = require 'simpleheat'
  require './index.styl'

DEFAULT_MAX = 2

module.exports = class HeatMapWidget
  type: 'Widget'

  constructor: ({@dimensions}) ->
    @state = z.state
      dimensions: @dimensions

  afterMount: ($$el) =>
    @heat = simpleheat $$el
    @heat.gradient {
      0.4: colors.getByGroupKey 'nickatnyte', '--tertiary-900'
      0.6: colors.getByGroupKey 'nickatnyte', '--tertiary-700'
      0.7: colors.getByGroupKey 'nickatnyte', '--tertiary-500'
      0.8: colors.getByGroupKey 'nickatnyte', '--primary-300'
      1.0: colors.getByGroupKey 'nickatnyte', '--primary-500'
    }

    @dimensions.subscribe (dimensions) =>
      @heat.radius dimensions?.width * 0.03, dimensions?.width * 0.02
      setTimeout =>
        @heat.resize()
      , 50

  setMax: (max) =>
    @heat?.max max or DEFAULT_MAX

  setDataPoints: (data) =>
    @heat?.data data
    @heat?.draw()

  render: =>
    {dimensions} = @state.getValue()

    z 'canvas.z-heat-map-widget',
      style:
        width: "#{dimensions?.width}px"
        height: "#{dimensions?.height}px"
      width: dimensions?.width
      height: dimensions?.height
