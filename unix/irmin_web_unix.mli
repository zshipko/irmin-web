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

module Make(Store: Irmin_graphql.Server.S): sig
  include Irmin_web.S with type store = Store.store and type server = Cohttp_lwt_unix.Server.t

  val run :
    ?allow_mutations:bool ->
    ?ssl:(string * string) ->
    ?addr:string ->
    ?port:int ->
    title:string ->
    css:string ->
    js:string ->
    html:string ->
    store -> unit Lwt.t
end
