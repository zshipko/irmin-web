(*---------------------------------------------------------------------------
   Copyright (c) 2018 Zach Shipko. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Lwt.Infix

external realpath: string -> string = "ml_realpath"

let irmin_js = [%blob "../../js/irmin.js"]

module Make(Store: Irmin.S) = struct

  module Graphql = Irmin_graphql.Make(Store)

  type t = {
    cfg: Irmin.config;
    repo: Store.repo;
  }

  let create cfg =
    Store.Repo.v cfg >|= fun repo ->
    {cfg; repo}

  let start_graphql_server t port =
    Store.Repo.v t.cfg >>= fun repo ->
    Store.master repo >>= fun master ->
    Graphql.start_server ~port master

  let run ?(addr = "localhost") ?(port = 5089) ?(static = "./static") t =
    let open Yurt.Server in
    let static = realpath static in
    let graphql_port = port + 1 in
    let graphql_address = Printf.sprintf "http://localhost:%d/graphql" graphql_port in
    Lwt.async (fun () -> start_graphql_server t graphql_port);
    server addr port
    >| post "/graphql" (fun req _params body ->
      let headers = Yurt.Request.headers req in
      Yurt.Client.post ~headers ~body graphql_address >>= fun (_, body) -> string body)
    >| get "/irmin.js" (fun _req _params _body -> string ~headers:(Yurt.Header.of_list ["Content-Type", "text/javacript"]) irmin_js)
    >| folder (Filename.concat static "js") "static/js"
    >| folder (Filename.concat static "css") "static/css"
    >| static_file (Filename.concat static "index.html") ""
    |> start

  let run_simple ?(addr = "localhost") ?(port = 5089) ~css ~js ~html t =
    let html' = html in
    let open Yurt.Server in
    let graphql_port = port + 1 in
    let graphql_address = Printf.sprintf "http://localhost:%d/graphql" graphql_port in
    Lwt.async (fun () -> start_graphql_server t graphql_port);
    server addr port
    >| post "/graphql" (fun req _params body ->
      let headers = Yurt.Request.headers req in
      Yurt.Client.post ~headers ~body graphql_address >>= fun (_, body) -> string body)
    >| get "/irmin.js" (fun _req _params _body -> string ~headers:(Yurt.Header.of_list ["Content-Type", "text/javacript"]) irmin_js)
    >| get ("/static/js/" ^ fst js) (fun _req _params _body -> string ~headers:(Yurt.Header.of_list ["Content-Type", "text/javacript"]) (snd js))
    >| get ("/static/css/" ^ fst css) (fun _req _params _body -> string ~headers:(Yurt.Header.of_list ["Content-Type", "text/css"]) (snd css))
    >| get "/" (fun _req _params _body -> string ~headers:(Yurt.Header.of_list ["Content-Type", "text/html"]) html')
    |> start
end

module Cli = struct
  open Cmdliner

  let port =
    let doc = "Port to listen on" in
    Arg.(value & pos 0 (some int) None & info [] ~docv:"PORT" ~doc)

  let contents =
    let doc = "Content type" in
    Arg.(value & opt string "string" & info ["c"; "contents"] ~docv:"CONTENTS" ~doc)

  let store =
    let doc = "Store type" in
    Arg.(value & opt string "git" & info ["s"; "store"] ~docv:"STORE" ~doc)

  let root =
    let doc = "Store location" in
    Arg.(value & opt string "/tmp/irmin" & info ["root"] ~docv:"PATH" ~doc)

  let static =
    let doc = "Static path" in
    Arg.(value & opt string "static" & info ["static"] ~docv:"PATH" ~doc)

  let config path =
    let head = Git.Reference.of_string "refs/heads/master" in
    Irmin_git.config ~head path

  let run_simple name ~css ~js ~html =
    let run port root contents store =
      let c = Irmin_unix.Cli.mk_contents contents in
      let (module Store) = Irmin_unix.Cli.mk_store store c in
      let module Server = Make(Store) in
      let p =
        Server.create (config root) >>= fun server ->
        Server.run_simple ~css ~js ~html ?port server
      in Lwt_main.run p
    in
    let main_t = Term.(const run $ port $ root $ contents $ store) in
    Term.exit @@ Term.eval (main_t, Term.info name)

  let run name =
    let run port root contents store static =
      let c = Irmin_unix.Cli.mk_contents contents in
      let (module Store) = Irmin_unix.Cli.mk_store store c in
      let module Server = Make(Store) in
      let p =
        Server.create (config root) >>= fun server ->
        Server.run ~static ?port server
      in Lwt_main.run p
    in
    let main_t = Term.(const run $ port $ root $ contents $ store $static) in
    Term.exit @@ Term.eval (main_t, Term.info name)
end

(*---------------------------------------------------------------------------
   Copyright (c) 2018 Zach Shipko

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
