(*---------------------------------------------------------------------------
  Copyright (c) 2018 Zach Shipko. All rights reserved. Distributed under the
  ISC license, see terms at the end of the file. %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Lwt.Infix
module Store = Irmin_unix.Git.FS.KV (Irmin.Contents.String)
module Graphql = Irmin_unix.Graphql.Server.Make(Store)(struct
  let remote = Some Store.remote
end)

module Server = Irmin_web.Make (Cohttp_lwt_unix.Server) (Graphql)

let html = [%blob "../../test/test.html"]
let js = [%blob "../../test/test.js"]
let css = [%blob "../../test/test.css"]

let main =
  let cfg = Irmin_git.config "./tmp" in
  Store.Repo.v cfg
  >>= Store.master
  >>= fun s ->
  let server = Server.config ~allow_mutations:true  ~title:"Irmin.js Test Suite" ~html ~js ~css s in
  let server = Server.make server ~addr:"localhost" ~port:8080 in
  let on_exn _ = () in
  let mode = `TCP (`Port 8080) in
  Conduit_lwt_unix.init ~src:"localhost" () >>= fun ctx ->
  let ctx = Cohttp_lwt_unix.Net.init ~ctx () in
  Cohttp_lwt_unix.Server.create ~on_exn ~mode ~ctx server

let _ = Lwt_main.run main

(*---------------------------------------------------------------------------
  Copyright (c) 2018 Zach Shipko

  Permission to use, copy, modify, and/or distribute this software for any
  purpose with or without fee is hereby granted, provided that the above
  copyright notice and this permission notice appear in all copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
  REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
  AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
  INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
  LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
  OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
  PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
