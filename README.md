# PostgreSQL using node-postgres for NoFlo <br/>[![Build Status](https://secure.travis-ci.org/kenhkan/noflo-pg.png?branch=master)](http://travis-ci.org/kenhkan/noflo-pg) [![Dependency Status](https://gemnasium.com/kenhkan/noflo-pg.png)](https://gemnasium.com/kenhkan/noflo-pg) [![NPM version](https://badge.fury.io/js/noflo-pg.png)](http://badge.fury.io/js/noflo-pg) [![Stories in Ready](https://badge.waffle.io/kenhkan/noflo-pg.png)](http://waffle.io/kenhkan/noflo-pg)

This is a simple wrapper around [brianc](https://github.com/brianc/)'s
[node-postgres](https://github.com/brianc/node-postgres).

Feel free to contribute new components and graphs! I'll try to
incorporate as soon as time allows.


## Usage

Although some components may be of interest in some situations, most
likely you want to use the 'Postgres' graph.

    'tcp://localhost:5432/postgres' - SERVER Postgres(pg/Postgres)
    'SELECT * FROM users WHERE uuid = &uuid' -> TEMPLATE Postgres()
    'id' -> TOKEN Postgres()
    'uuid' -> GROUP Placeholder(Group)
    '1234' -> IN Placeholder() OUT -> IN Postgres()
    Postgres() OUT -> IN PrintUsers(Output)
    Postgres() ERROR -> IN Error(Output)

This would yield:

    SELECT * FROM users WHERE uuid = '1234';

Template accepts an SQL string with placeholders starting with
ampersands. The SQL string is *not* sanitized for injection attacks.
Then, pass in values grouped by the placeholder strings to Postgres.
These values are sanitized for injection attacks.

Whether PostgreSQL returns any row or not, it sends to the 'OUT' port.
If there's an error, it sends it to the 'ERROR' port.

Note that since this is an asynchronous operation, you must provide a
token which would group the output for you to identify the output
corresponding to your input.

Feel free to create as many instances of `pg/Client`. All queries are
pooled in a single connection.

#### Escaping Sanitization

When the placeholder or the replacement itself is prepended with an
ampersand, the replacement is not sanitized. This is useful when
constructing SQL statements.

    'tcp://localhost:5432/postgres' - SERVER Postgres(pg/Postgres)
    'SELECT * FROM &table' -> TEMPLATE Postgres()
    'table' -> GROUP Placeholder(Group)
    'users' -> IN Placeholder() OUT -> IN Postgres()
    ...

The above would yield:

    SELECT * FROM users;
