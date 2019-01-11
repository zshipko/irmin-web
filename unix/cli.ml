open Cmdliner
open Lwt.Infix

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

let js_file =
  let doc = "Javascript file path" in
  Arg.(value & opt (some string) None & info ["js"] ~docv:"FILENAME" ~doc)

let css_file =
  let doc = "CSS file path" in
  Arg.(value & opt (some string) None & info ["css"] ~docv:"FILENAME" ~doc)

let html_file =
  let doc = "HTML file path" in
  Arg.(value & opt (some string) None & info ["html"] ~docv:"FILENAME" ~doc)

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

let get_string a b default =
  match a with
  | Some x -> x
  | None ->
    (match b with
     | Some x -> x
     | None -> default ())

let read_file filename =
  match filename with
  | None -> None
  | Some f ->
    let c = open_in f in
    let len = in_channel_length c in
    let s = really_input_string c len in
    close_in c; Some s


let run ?print_info:(pi = true) ?title ?html ?css ?js name =
  let run address port
      (Irmin_unix.Resolver.S ((module Store), store, remote_fn))
      allow_mutations ssl
      page_title html_file css_file js_file =
    let title = get_string page_title title (fun () -> "") in
    let html = get_string (read_file html_file) html (fun () -> "") in
    let js = get_string (read_file js_file) js (fun () -> failwith "Javascript file is required") in
    let css = get_string (read_file css_file) css (fun () -> "") in
    let module Config = struct
      let remote = remote_fn
    end in
    let module Graphql = Irmin_unix.Graphql.Server.Make(Store)(Config) in
    let module Server = Web.Make(Graphql) in
    if pi then Printf.printf "Running irmin-web on %s:%d\n" address port;
    Lwt_main.run (store >>= fun store -> Server.run ?ssl ~allow_mutations ~title ~css ~js ~html ~addr:address ~port store)
  in
  let main_t =
    Term.(
      const run
      $ address
      $ port
      $ Irmin_unix.Resolver.store
      $ mutations
      $ ssl
      $ page_title
      $ html_file
      $ css_file
      $ js_file)
  in
  Term.exit @@ Term.eval (main_t, Term.info name)
