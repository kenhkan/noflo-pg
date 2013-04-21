test = require "noflo-test"

test.component("postgres/Sanitize").
  discuss("escape unquoted content").
    send.data("in", "812387").
    discuss("into quoted content").
      receive.data("out", "'812387'").
  next().
  discuss("excessive quotes?").
    send.data("in", "akld'fsl").
    discuss("get rid of them").
      receive.data("out", "'akld''fsl'").
  next().
  discuss("uneven quotes?").
    send.data("in", "'''kdi''").
    discuss("make them event").
      receive.data("out", "'''kdi'''").

export module
