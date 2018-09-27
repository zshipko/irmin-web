open Lwt.Infix
open Cmdliner

let port =
  let doc = "Port to listen on" in
  Arg.(value & opt int 8080 & info ["p"; "port"] ~docv:"PORT" ~doc)

let address =
  let doc = "Address to listen on" in
  Arg.(value & opt string "localhost" & info ["a"; "address"] ~docv:"ADDR" ~doc)

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
  let doc = "Static file path" in
  Arg.(required & pos 0 (some string) None  & info [] ~docv:"STATIC" ~doc)

let mutations =
  let doc = "Enable/disable mutations" in
  Arg.(value & opt bool true & info ["mutations"] ~docv:"ALLOWED" ~doc)

let config path =
  let head = Git.Reference.of_string "refs/heads/master" in
  Irmin_git.config ~head path

let print_info port static =
  Lwt_io.printlf "Running irmin-web\n\n\tport = %d\n\tstatic dir = %s" port static

let run_simple ?print_info:(pi = true) name ~css ~js ~html =
  let run address port (Irmin_unix.Resolver.S ((module Store), store, remote_fn)) allow_mutations =
    let module Store = struct
      include Store
      let info = Irmin_unix.info
      let remote = remote_fn
    end in
    let module Server = Web.Make(Store) in
    let p =
      store >>= fun store ->
      let server = Server.create ~allow_mutations store in
      (if pi then
        print_info port "<simple>"
      else Lwt.return ()) >>= fun () ->
      Server.run_simple ~addr:address ~css ~js ~html ~port server
    in Lwt_main.run p
  in
  let main_t = Term.(const run $ address $ port $ Irmin_unix.Resolver.store $ mutations) in
  Term.exit @@ Term.eval (main_t, Term.info name)

let run ?print_info:(pi = true) name =
  let run address port (Irmin_unix.Resolver.S ((module Store), store, remote_fn)) static allow_mutations =
    let module Store = struct
      include Store
      let info = Irmin_unix.info
      let remote = remote_fn
    end in
    let module Server = Web.Make(Store) in
    let module Server = Web.Make(Store) in
    let p =
      store >>= fun store ->
        let server = Server.create ~allow_mutations store in
      (if pi then
        print_info port static
      else Lwt.return ()) >>= fun () ->
      Server.run ~addr:address ~static ~port server
    in Lwt_main.run p
  in
  let main_t = Term.(const run $ address $ port $ Irmin_unix.Resolver.store $ static $ mutations) in
  Term.exit @@ Term.eval (main_t, Term.info name)
