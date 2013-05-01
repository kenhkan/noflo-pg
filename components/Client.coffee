_ = require("underscore")
pg = require("pg")
noflo = require("noflo")

# Pool all queries through a single connection for each database
client = {}

class Client extends noflo.Component

  description: "An interface to the backend PostgreSQL database"

  constructor: ->
    @token = null

    @inPorts =
      in: new noflo.Port()
      server: new noflo.Port()
      token: new noflo.Port()
      quit: new noflo.Port()
    @outPorts =
      out: new noflo.Port()
      error: new noflo.Port()

    # Close connection on application exit, SIGINT, and SIGTERM
    endServer = _.bind @endServer, this
    process.on "exit", endServer
    process.on "SIGINT", endServer
    process.on "SIGTERM", endServer
    process.on "SIGHUP", endServer

    @inPorts.token.on "data", (@token) =>

    @inPorts.server.on "data", (@url) =>
      @startServer @url
    @inPorts.quit.on "data", (@url) =>
      @endServer @url

    @inPorts.in.on "connect", =>
      @sqls = []

    @inPorts.in.on "data", (data) =>
      @sqls.push data

    @inPorts.in.on "disconnect", =>
      token = @token
      query = _.flatten(@sqls).join(";\n")

      unless client[@url]?
        throw new Error "Server connection has not yet been established"
      unless token?
        throw new Error "Missing token for return connection"
      unless query?
        throw new Error "Missing query to execute"

      result = client[@url].query query

      # Send row forward
      result.on "row", (row, result) =>
        result.addRow row

      # Send to error port
      result.on "error", (e) =>
        unless @outPorts.error.isAttached()
          throw new Error "No error port attached"

        @outPorts.error.send e
        @outPorts.error.disconnect()

      result.on "end", (result) =>
        @outPorts.out.beginGroup token
        @outPorts.out.send row for row in result?.rows or []
        @outPorts.out.endGroup()
        @outPorts.out.disconnect()

  startServer: (url) ->
    @endServer url
    client[url] = new pg.Client url
    client[url].connect()

  endServer: (url) ->
    client[url]?.end()

exports.getComponent = -> new Client
