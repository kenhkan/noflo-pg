_ = require("underscore")
pg = require("pg")
noflo = require("noflo")

# Pool all queries through a single connection for each database
clients = {}

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
      client = clients[@url]
      token = @token
      query = _.flatten(@sqls).join(";\n")

      unless client?
        throw new Error "Server connection has not yet been established"
      unless token?
        throw new Error "Missing token for return connection"
      unless query?
        throw new Error "Missing query to execute"

      result = client.query query

      # Send row forward
      result.on "row", (row, result) =>
        result.addRow row

      # Send to error port
      result.on "error", (e) =>
        unless @outPorts.error.isAttached()
          throw new Error "No error port attached"

        e.query = query
        @outPorts.error.send e
        @outPorts.error.disconnect()

        # Re-connect to avoid persisting errors
        @startServer @url

      result.on "end", (result) =>
        rows = result?.rows or []
        @outPorts.out.beginGroup token
        if _.isEmpty rows
          @outPorts.out.send null
        else
          @outPorts.out.send row for row in rows
        @outPorts.out.endGroup()
        @outPorts.out.disconnect()

  startServer: (url) ->
    @endServer url
    clients[url] = new pg.Client url
    clients[url].connect()

  endServer: (url) ->
    if url?
      clients[url]?.end()
    else
      clients[url].end() for url in _.keys clients

exports.getComponent = -> new Client
