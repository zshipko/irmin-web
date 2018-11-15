open Lwt.Infix
open Cmdliner

let port =
  let doc = "Port to listen on" in
  Arg.(value & opt int 8080 & info ["p"; "port"] ~docv:"PORT" ~doc)

let address =
  let doc = "Address to listen on" in
  Arg.(
    value & opt string "localhost" & info ["a"; "address"] ~docv:"ADDR" ~doc)

let ssl =
  let doc = "A comma separated pair of ssl certificate and ssl key" in
  Arg.(
    value
    & opt (some @@ pair ~sep:',' string string) None
    & info ["ssl"] ~docv:"SSL_CONFIG" ~doc)

let static =
  let doc = "Static file path" in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"STATIC" ~doc)

let page_title =
  let doc = "HTML title" in
  Arg.(value & opt (some string) None & info ["title"] ~docv:"TITLE" ~doc)

let mutations =
  let doc = "Enable/disable mutations" in
  Arg.(value & opt bool true & info ["mutations"] ~docv:"ALLOWED" ~doc)

let config path =
  let head = Git.Reference.of_string "refs/heads/master" in
  Irmin_git.config ~head path

let print_info port static =
  Lwt_io.printlf "Running irmin-web\n\n\tport = %d\n\tstatic dir = %s" port
    static

let ssl_config = function
  | None ->
    None
  | Some (crt, key) ->
    Some (`Certificate crt, `Key key)

let run ?print_info:(pi = true) name ?title ~css ~js ~html =
  let run address port
      (Irmin_unix.Resolver.S ((module Store), store, remote_fn))
      allow_mutations page_title ssl =
    let title =
      match page_title with
      | Some t ->
        t
      | None -> (
        match title with
        | Some t ->
          t
        | None ->
          "" )
    in
    let module Store = struct
      include Store

      let info = Irmin_unix.info
      let remote = remote_fn
    end in
    let module Server = Web.Make (Store) in
    let p =
      store
      >>= fun store ->
      let server = Server.create ~allow_mutations store in
      (if pi then print_info port "<simple>" else Lwt.return ())
      >>= fun () ->
      Server.run ?ssl:(ssl_config ssl) ~addr:address ~title ~css ~js ~html
        ~port server
    in
    Lwt_main.run p
  in
  let main_t =
    Term.(
      const run
      $ address
      $ port
      $ Irmin_unix.Resolver.store
      $ mutations
      $ page_title
      $ ssl)
  in
  Term.exit @@ Term.eval (main_t, Term.info name)

let run_custom ?print_info:(pi = true) name =
  let run address port
      (Irmin_unix.Resolver.S ((module Store), store, remote_fn)) static
      allow_mutations ssl =
    let module Store = struct
      include Store

      let info = Irmin_unix.info
      let remote = remote_fn
    end in
    let module Server = Web.Make (Store) in
    let p =
      store
      >>= fun store ->
      let server = Server.create ~allow_mutations store in
      (if pi then print_info port static else Lwt.return ())
      >>= fun () ->
      Server.run_custom ?ssl:(ssl_config ssl) ~addr:address ~static ~port
        server
    in
    Lwt_main.run p
  in
  let main_t =
    Term.(
      const run
      $ address
      $ port
      $ Irmin_unix.Resolver.store
      $ static
      $ mutations
      $ ssl)
  in
  Term.exit @@ Term.eval (main_t, Term.info name)
