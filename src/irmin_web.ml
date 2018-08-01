(*---------------------------------------------------------------------------
   Copyright (c) 2018 Zach Shipko. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Lwt.Infix

module Store = Irmin_unix.Git.FS.KV(Irmin.Contents.Json)
module Graphql = Irmin_graphql.Make(Store)

let js = [%blob "../../js/irmin.js"]

external realpath: string -> string = "ml_realpath"

module Server = struct
  type t = {
    cfg: Irmin.config;
    repo: Store.repo;
  }

  let create ?head ?bare root =
    let cfg = Irmin_git.config ?head ?bare root in
    Store.Repo.v cfg >|= fun repo ->
    {cfg; repo}

  let start_graphql_server t port =
    Store.Repo.v t.cfg >>= fun repo ->
    Store.master repo >>= fun master ->
    Graphql.start_server ~port master

  let run ?(addr = "localhost") ?(port = 5089) ?(static = "./static") t =
    let open Yurt.Server in
    let static = realpath static in
    print_endline (Unix.getcwd ());
    print_endline static;
    let graphql_port = port + 1 in
    let graphql_address = Printf.sprintf "http://localhost:%d/graphql" graphql_port in
    Lwt.async (fun () -> start_graphql_server t graphql_port);
    server addr port
    >| post "/graphql" (fun req _params body ->
      let headers = Yurt.Request.headers req in
      Yurt.Client.post ~headers ~body graphql_address >>= fun (_, body) -> string body)
    >| get "/irmin.js" (fun _req _params _body -> string ~headers:(Yurt.Header.of_list ["Content-Type", "text/javacript"]) js)
    >| folder (Filename.concat static "js") "static/js"
    >| folder (Filename.concat static "css") "static/css"
    >| static_file (Filename.concat static "index.html") ""
    |> start
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
