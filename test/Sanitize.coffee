test = require "noflo-test"

test.component("pg/Sanitize").
  discuss("escape unquoted content").
    send.data("in", "abc123").
    discuss("into quoted content").
      receive.data("out", "'abc123'").

  next().
  discuss("but not numbers").
    send.data("in", "812387").
    discuss("which are unquoted").
      receive.data("out", "812387").

  next().
  discuss("partial numbers parsable by `parseInt`").
    send.data("in", "123abc").
    discuss("are also turned into numbers").
      receive.data("out", "123").

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
