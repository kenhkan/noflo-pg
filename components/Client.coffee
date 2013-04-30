_ = require("underscore")
pg = require("pg")
noflo = require("noflo")

class Client extends noflo.Component

  description: "An interface to the backend PostgreSQL database"

  constructor: ->
    @inPorts =
      in: new noflo.Port()
      server: new noflo.Port()
    @outPorts =
      out: new noflo.Port()
      error: new noflo.Port()

    # Close connection on application exit, SIGINT, and SIGTERM
    endServer = _.bind(@endServer, this)
    process.on("exit", endServer)
    process.on("SIGINT", endServer)
    process.on("SIGTERM", endServer)
    process.on("SIGHUP", endServer)

    @inPorts.server.on "data", (url) =>
      @startServer url

    @inPorts.in.on "connect", =>
      @groups = []
      @sqls = []

    @inPorts.in.on "begingroup", (group) =>
      @groups.push(group)

    @inPorts.in.on "data", (data) =>
      @sqls.push(data)

    @inPorts.in.on "disconnect", =>
      unless @client?
        throw new Error "Server connection has not yet been established"

      groups = @groups
      query = _.flatten(@sqls).join(";\n")
      result = @client.query(query)

      # Send row forward
      result.on "row", (row, result) =>
        result.addRow(row)

      # Send to error port
      result.on "error", (e) =>
        @outPorts.error.send(e)
        @outPorts.error.disconnect()

      result.on "end", (result) =>
        @sendResult(@outPorts.out, groups, result?.rows or [])

  sendResult: (port, groups, result) ->
    port.beginGroup(group) for group in groups
    port.send(result)
    port.endGroup(group) for group in groups
    port.disconnect()

  startServer: (url) ->
    @endServer()
    @client = new pg.Client(url)
    @client.connect()

  endServer: ->
    @client?.end()

exports.getComponent = -> new Client
