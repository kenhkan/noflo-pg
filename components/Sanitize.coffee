noflo = require("noflo")
_ = require("underscore")

class Sanitize extends noflo.Component

  description: "Makes sure the provided string pairs safe for SQL injection"

  constructor: ->
    @inPorts =
      in: new noflo.Port
    @outPorts =
      out: new noflo.Port

    @inPorts.in.on "begingroup", (group) =>
      @outPorts.out.beginGroup group

    @inPorts.in.on "data", (data) =>
      # Ignore if data starts with an ampersand (an escape), but remove the
      # ampersand of course
      if data?.match?(/^&/)?
        data = data.slice 1

      else if data is ""
        data = "''"

      else if _.isArray(data)
        data = "(#{_.map(data, @quote).join(", ")})"

      else if _.isString(data)
        # Remove duplicate quotes and for each remaining quote escape the quote
        # for SQL
        data = "'#{data.replace(/'+/g, "'").replace(/'/g, "''")}'"

      else if _.isNumber(data)
        data = @quote data

      else
        data = "''"

      @outPorts.out.send data

    @inPorts.in.on "endgroup", (group) =>
      @outPorts.out.endGroup()

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect()

  quote: (string) ->
    "'#{string}'"

exports.getComponent = -> new Sanitize
