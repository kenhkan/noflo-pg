_ = require("underscore")
pg = require("pg")
noflo = require("noflo")

class Postgres extends noflo.Component

  description: "An interface to the backend PostgreSQL database"

  constructor: ->
    @inPorts =
      in: new noflo.Port()
      server: new noflo.Port()
    @outPorts =
      out: new noflo.Port()
      error: new noflo.Port()
      empty: new noflo.Port()

    # Close connection on application exit, SIGINT, and SIGTERM
    endServer = _.bind(@endServer, this)
    process.on("exit", endServer)
    process.on("SIGINT", endServer)
    process.on("SIGTERM", endServer)
    process.on("SIGHUP", endServer)

    @inPorts.server.on "data", (data) =>
      @startServer(data)

    @inPorts.in.on "connect", =>
      @groups = []
      @sqls = []

    @inPorts.in.on "begingroup", (group) =>
      @groups.push(group)

    @inPorts.in.on "data", (data) =>
      @sqls.push(data)

    @inPorts.in.on "disconnect", =>
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
        rows = result?.rows or []

        if rows.length > 0
          @sendResult(@outPorts.out, groups, rows)
        else
          @sendResult(@outPorts.empty, groups, rows)

  sendResult: (port, groups, result) ->
    for group in groups
      port.beginGroup(group)

    port.send(result)

    for group in groups
      port.endGroup(group)

    port.disconnect()

  startServer: (url) ->
    @endServer()
    @client = new pg.Client(url)
    @client.connect()

  endServer: ->
    @client?.end()

exports.getComponent = -> new Postgres
