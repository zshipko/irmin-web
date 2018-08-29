irmin-web
-------------------------------------------------------------------------------
%%VERSION%%

irmin-web is a tool for building web applications using Irmin. It uses [irmin.js](https://github.com/zshipko/irmin-web/blob/master/js/irmin.js) to communicate with an [irmin-graohql](https://github.com/andreas/irmin-graphql) server.

irmin-web is distributed under the ISC license.

Homepage: https://github.com/zshipko/irmin-web

## Installation

`irmin-web` depends on [irmin-graphql](https://github.com/andreas/irmin-graphql) and [yurt](https://github.com/zshipko.yurt):

irmin-web can be installed with `opam`:

    opam pin add irmin-web https://github.com/zshipko/irmin-web.git

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Getting started

Here is an example of a single page application with one HTML file, one JS file and one CSS file:

```ocaml
let css = ("index.css", {| body {background: read; color: white;} |})
let js = ("index.js", {|\
ir.master().then((t) => {
    document.querySelector(".hash").innerHTML = t.head.hash;
})
})
let html = {|
<html>
    <head>
        <link rel="stylesheet" href="/static/css/index.css" />
        <script src="/irmin.js"></script>
    </head>
    <body>
        <div class="hash"></div>
        <script src="/static/js/index.js"></script>
    </body>
</html>
|}
let _ =
Irmin_web.Cli.run_simple ~css ~js ~html "irmin-dashboard"
```

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
