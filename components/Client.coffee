_ = require("underscore")
pg = require("pg")
noflo = require("noflo")

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
    endServer = _.bind(@endServer, this)
    process.on("exit", endServer)
    process.on("SIGINT", endServer)
    process.on("SIGTERM", endServer)
    process.on("SIGHUP", endServer)

    @inPorts.quit.on "disconnect", =>
      @endServer()

    @inPorts.token.on "data", (@token) =>

    @inPorts.server.on "data", (url) =>
      @startServer url

    @inPorts.in.on "connect", =>
      @sqls = []

    @inPorts.in.on "data", (data) =>
      @sqls.push(data)

    @inPorts.in.on "disconnect", =>
      token = @token
      query = _.flatten(@sqls).join(";\n")

      unless @client?
        throw new Error "Server connection has not yet been established"
      unless token?
        throw new Error "Missing token for return connection"
      unless query?
        throw new Error "Missing query to execute"

      result = @client.query query

      # Send row forward
      result.on "row", (row, result) =>
        result.addRow(row)

      # Send to error port
      result.on "error", (e) =>
        unless @outPorts.error.isAttached()
          throw new Error "No error port attached"

        @outPorts.error.send(e)
        @outPorts.error.disconnect()

      result.on "end", (result) =>
        port = @outPorts.out
        output = result?.rows or []

        port.beginGroup token
        port.send output
        port.endGroup()
        port.disconnect()

  startServer: (url) ->
    @endServer()
    @client = new pg.Client(url)
    @client.connect()

  endServer: ->
    @client?.end()

exports.getComponent = -> new Client
