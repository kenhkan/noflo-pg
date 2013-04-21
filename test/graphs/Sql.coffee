# TODO: Re-write test case when noflo-test supports graphs
#
# spy = require("components/Spy")
# fixtures = require("fixtures/setup")
# noflo = require("noflo")
# postgres = require("components/Postgres")

# exports.setUp = (done) ->
#   postgres.setup()
#   fixtures.load("users", done)

# exports.tearDown = (done) ->
#   postgres.teardown()
#   spy.clear()
#   fixtures.unload("users", done)

# exports["updates (or inserts) a record in the database"] = (test) ->
#   test.expect(2)

#   fbp = """
#     'graphs/Sql.fbp' -> GRAPH Graph(Graph)

#     'SELECT * FROM things WHERE type = \'users\' AND uuid = &uuid' -> IN Graph.Sql()
#     Graph.Output() OUT -> END A(Spy)

#     'uuid' -> GROUP Id(Group)
#     '#{"'id21'"}' -> IN Id() OUT -> IN Graph.Input()
#   """

#   noflo.graph.loadFBP fbp, (graph) ->
#     noflo.createNetwork graph, (network) ->
#       [a] = spy.getSpies()

#       f = ->
#         unless spy.findAll(a, "data").length is 1
#           process.nextTick(f)
#           return

#         record = spy.find(a, "data")
#         user =
#           uuid: "id21"
#           type: "users"

#         test.equal(record.name, user.name)
#         test.equal(record.email, user.email)

#         test.done()

#       do f
