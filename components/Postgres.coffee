pg = require("pg")
_ = require("underscore")
_s = require("underscore.string")
noflo = require("noflo")
config = require("config")
owl = require("owl-deepcopy")

# The singleton database connection
client = null

# Set up
exports.setup = ->
  exports.teardown()
  client = new pg.Client(config.DATABASE)
  client.connect()

# Tear down procedure
exports.teardown = ->
  client?.end()
  client = null

# Close connection on application exit, SIGINT, and SIGTERM
process.on("exit", exports.teardown)
process.on("SIGINT", exports.teardown)
process.on("SIGTERM", exports.teardown)
process.on("SIGHUP", exports.teardown)

# An interface to the backend PostgreSQL database
class Postgres extends noflo.Component

  description: "An interface to the backend PostgreSQL database"

  constructor: ->
    # Ports
    @inPorts =
      in: new noflo.Port()
    @outPorts =
      out: new noflo.Port()
      error: new noflo.Port()
      empty: new noflo.Port()

    @inPorts.in.on "connect", =>
      @groups = []
    @inPorts.in.on "begingroup", (group) =>
      @groups.push(group)

    @inPorts.in.on "disconnect", =>
      groups = @groups
      data = @inPorts.in.getBufferData()
      query = _.flatten(data).join(";\n")

      # Clean up inPort
      @inPorts.in.clearBuffer()

      # Initialize client if necessary
      unless client?
        exports.setup()

      # Fetch result
      result = client.query(query)

      # Send row forward
      result.on "row", (row, result) =>
        result.addRow(row)

      # Send to error port
      result.on "error", (e) =>
        if @outPorts.error.isAttached()
          @outPorts.error.send(e)
          @outPorts.error.disconnect()
        else
          throw new Error _.clean "Postgres.in.data | No error port is
            attached and query '#{query}' yields '#{e}'"

      result.on "end", (result) =>
        rows = result?.rows or []

        if rows.length > 0
          @sendResult(@outPorts.out, groups, rows)

        # No rows and empty port is attached
        else if @outPorts.empty.isAttached()
          @sendResult(@outPorts.empty, groups, rows)

        # Report error
        else
          throw new Error _.clean "Postgres.in.data | No empty port is
            attached and query '#{query}' yields no rows."

  sendResult: (port, groups, result) ->
    for group in groups
      port.beginGroup(group)

    port.send(result)

    for group in groups
      port.endGroup(group)

    port.disconnect()

exports.getComponent = -> new Postgres
