config = require '../config'

PATH = config.BACKEND_API_URL

module.exports = class Poll
  constructor: ({@auth}) -> null

  upsert: ({poll}) =>
    @auth.call 'polls.upsert', {poll}, {invalidateAll: true}

  getById: (id) =>
    @auth.stream 'polls.getById', {id}

  getAllByGroupId: (groupId) =>
    @auth.stream 'polls.getAllByGroupId', {groupId}, {isStreamed: true}

  voteById: (id, {value}) =>
    @auth.call 'polls.voteById', {id, value}#, {invalidateAll: true}

  resetById: (id) =>
    @auth.call 'polls.resetById', {id}, {invalidateAll: true}

  getAllVotesById: (id) =>
    @auth.stream 'polls.getAllVotesById', {id}, {isStreamed: true}
