(*---------------------------------------------------------------------------
   Copyright (c) 2018 Zach Shipko. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Lwt.Infix

module Store = Irmin_unix.Git.FS.KV(Irmin.Contents.Json)
module Graphql = Irmin_graphql.Make(Store)

module Server = struct
  type t = {
    repo: Store.repo;
  }

  let create ?head ?bare root =
    let cfg = Irmin_git.config ?head ?bare root in
    Store.Repo.v cfg >|= fun repo ->
    {repo}

  let start_graphql_server t port =
    Store.master t.repo >>= fun master ->
    Lwt_io.flush_all () >|= fun () ->
    match Lwt_unix.fork () with
    | -1 -> -1
    | 0 ->
        let cmd = Graphql.start_server ~port master in
        Lwt_main.run cmd; 0
    | n -> n

  let run ?(addr = "localhost") ?(port = 5089) ?(static = "./static") t =
    let open Yurt.Server in
    let graphql_port = port + 1 in
    let graphql_address = Printf.sprintf "http://localhost:%d" graphql_port in
    start_graphql_server t graphql_port >>= fun pid ->
    server addr port
    >| post "/graphql" (fun _req _params _body ->
      redirect graphql_address)
    >| folder (Filename.concat (Filename.concat static "static") "js") "static/js"
    >| folder (Filename.concat (Filename.concat static "static") "css") "static/css"
    >| static_file (Filename.concat static "index.html") ""
    |> start >|= fun () ->
    Unix.kill 9 pid
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
