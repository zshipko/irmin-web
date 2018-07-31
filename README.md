irmin-web
-------------------------------------------------------------------------------
%%VERSION%%

irmin-web is a tool for building websites using irmin-graphql

irmin-web is distributed under the ISC license.

Homepage: https://github.com/zshipko/irmin-web

## Installation

irmin-web can be installed with `opam`:

    opam install irmin-web

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Documentation

The documentation and API reference is generated from the source
interfaces. It can be consulted [online][doc] or via `odig doc
irmin-web`.

[doc]: https://zshipko.github.io/irmin-web/doc

## Tests

In the distribution sample programs and tests are located in the
[`test`](test) directory. They can be built and run
with:

    dune runtest
