test = require "noflo-test"

test.component("pg/Build").
  discuss("send in an SQL template").
    send.data("sql", "SELECT &fields FROM &tables WHERE &constraints").
  discuss("set defaults").
    send.beginGroup("default", "&fields").
    send.data("default", "*").
    send.endGroup("default").
  discuss("fill in the placeholders").
    send.beginGroup("in", "&tables").
    send.data("in", "users").
    send.data("in", "posts").
    send.endGroup("in").
    send.beginGroup("in", "&constraints").
    send.data("in", "posts.popularity > .3").
    send.endGroup("in").
    send.disconnect("in").
    discuss("out comes the entire SQL statement").
      receive.data("out", "SELECT * FROM users,posts WHERE posts.popularity > .3").

export module
