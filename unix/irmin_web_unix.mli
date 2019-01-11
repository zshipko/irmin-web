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
