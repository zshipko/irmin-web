irmin-web
-------------------------------------------------------------------------------
%%VERSION%%

irmin-web is a tool for building web applications using Irmin. It uses [irmin.js](https://github.com/zshipko/irmin-js) to communicate with an [irmin-graohql](https://github.com/andreas/irmin-graphql) server.

irmin-web is distributed under the ISC license.

Homepage: https://github.com/zshipko/irmin-web

## Installation

`irmin-web` depends on [irmin-graphql](https://github.com/andreas/irmin-graphql) and [yurt](https://github.com/zshipko.yurt):

irmin-web can be installed with `opam`:

    opam pin add irmin-web https://github.com/zshipko/irmin-web.git

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Getting started

The following is an example of a simple website that will display the hash of the latest commit on the master branch when the page is loaded.

css/index.css:

```css
body {
    background: black;
    color: white;
}
```

js/index.js:

```javascript
ir.master().then((t) => {
    document.querySelector(".hash").innerHTML = t.head.hash;
})
```

index.html:

```html
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
```

```ocaml
open Lwt.Infix
open Irmin_unix
module Store = Git.FS.KV(Irmin.Contents.String)
module Web = Irmin_web.Make(Store)

let config = Irmin_git.config "/tmp/irmin"

let main =
    let allow_mutations = false in
    Web.create ~allow_mutations config >>= fun t ->
    Web.run t

let () = Lwt_main.run main
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
