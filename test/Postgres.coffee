test = require "noflo-test"

expected = [
  { name: "Ken", age: 24 }
  { name: "Jenkin", age: 24 }
  { name: "Ken", age: 24 }
  { name: "Jenkin", age: 24 }
]

# TODO: some error with the database
#
# test.component("postgres/Postgres").
#   discuss("set up server").
#     send.data("server", "tcp://localhost:5432/postgres").
#   discuss("send in the SQL statements").
#     send.connect("in").
#       send.data("in", "CREATE TABLE people (name text, age integer);").
#     send.disconnect("in").
#     send.connect("in").
#       send.data("in", "INSERT INTO people VALUES ('Ken', 24), ('Jen', 24);").
#     send.disconnect("in").
#   discuss("groups are forwarded but hierarchy is lost").
#     send.connect("in").
#       send.beginGroup("in", "a").
#         send.beginGroup("in", "b").
#           send.data("in", "SELECT * FROM people where age = 24").
#         send.endGroup("in").
#       send.endGroup("in").
#       send.beginGroup("in", "c").
#         send.data("in", "SELECT * FROM people where age = 24").
#       send.endGroup("in").
#     send.disconnect("in").
#   discuss("get back the result").
#     # receive.beginGroup("out", "a").
#     # receive.beginGroup("out", "b").
#     # receive.beginGroup("out", "c").
#     receive.data("out", expected).
#     # receive.endGroup("out").
#     # receive.endGroup("out").
#     # receive.endGroup("out").

# export module
