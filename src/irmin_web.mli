(*---------------------------------------------------------------------------
  Copyright (c) 2018 Zach Shipko. All rights reserved. Distributed under the
  ISC license, see terms at the end of the file. %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Tools for building websites using irmin-graphql

    {e %%VERSION%% — {{:%%PKG_HOMEPAGE%% }homepage}} *)

(** {1 Irmin-web} *)

val read_file : string -> string

module Make (Store : Irmin_graphql.Server.S) : sig
  type t

  val create :
    ?allow_mutations:bool ->
    title:string ->
    html:string ->
    css:string ->
    js:string ->
    Store.store -> t

  val run :
       ?ssl:([`Certificate of string ] * [`Key of string])
    -> ?addr:string
    -> ?port:int
    -> t
    -> unit Lwt.t
end

module Cli : sig
  val run :
       ?print_info:bool
    -> ?title:string
    -> ?html:string
    -> ?css:string
    -> ?js:string
    -> string
    -> unit
end
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
