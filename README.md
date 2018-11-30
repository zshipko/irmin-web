irmin-web
-------------------------------------------------------------------------------
%%VERSION%%

irmin-web is a tool for building web applications using Irmin. It uses [irmin.js](https://github.com/zshipko/irmin-js) to communicate with an [irmin-graphql](https://github.com/andreas/irmin-graphql) server. The goal for this project is to keep it as generic as possible, allowing users to build whatever they'd like.

irmin-web is distributed under the ISC license.

Homepage: https://github.com/zshipko/irmin-web

## Installation

irmin-web can be installed with `opam`:

    opam pin add irmin-web https://github.com/zshipko/irmin-web.git

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

Additionally, there are some browser-based tests for `irmin-js`. To start the server:

```shell
$ make test
```

Then visit [http://localhost:8080](http://localhost:8080) to execute the tests.

## Example

See [irmin-dashboard](https://github.com/zshipko/irmin-web/tree/master/dashboard).

You can also run `irmin-dashboard` from the command line using `dune`:

```shell
$ dune exec dashboard/irmin_dashboard.exe" -- --root=/path/to/my/repo
```

## Docker

There is a Dockerfile in the project root that allows you to deploy your irmin-web projects:

```shell
$ docker build -f Dockerfile /path/to/my/static/dir
```

The static file path can also be set using an environment variable:

```shell
$ export IRMIN_WEB_ROOT=/path/to/my/static/dir
$ docker build .
```

## Documentation

The documentation and API reference is generated from the source
interfaces. It can be consulted [online][doc] or via `odig doc
irmin-web`.

[doc]: https://zshipko.github.io/irmin-web/doc


