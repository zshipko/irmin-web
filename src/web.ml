open Lwt.Infix
open Tyxml
open Cohttp_lwt_unix

let irmin_js = [%blob "../../js/irmin.js"]

let read_file filename =
  let ic = open_in filename in
  let len = in_channel_length ic in
  let res = really_input_string ic len in
  close_in ic; res

module Make (Store : Irmin_graphql.STORE) = struct
  module Graphql = Irmin_graphql.Make (Store)

  type t =
    { store : Store.t
    ; title: string
    ; html : string
    ; css : string
    ; js : string
    ; allow_mutations : bool }

  let create ?(allow_mutations = true) ~title ~html ~css ~js store = {store; title; html; css; js; allow_mutations}
  let start_graphql_server t port = Graphql.start_server ~port t.store

  let check t doc =
    let open Graphql_parser in
    if not t.allow_mutations then
      List.for_all
        (fun op ->
          match op with
          | Operation {optype = Mutation; _} ->
            false
          | _ ->
            true )
        doc
    else true

  let graphql t graphql_address req body =
    let headers = Cohttp.Request.headers req in
    Cohttp_lwt.Body.to_string body
    >>= fun body ->
    let json = Ezjsonm.from_string body in
    let query = Ezjsonm.find json ["query"] |> Ezjsonm.decode_string_exn in
    let doc = Graphql_parser.parse query in
    match doc with
    | Ok doc ->
      if check t doc then
        let body = Cohttp_lwt.Body.of_string body  in
        Client.post ~headers ~body graphql_address
        >>= fun (_, body) -> Server.respond ~status:`OK ~body ()
      else Server.respond_string ~status:`Unauthorized ~body:"Encountered blacklisted operation" ()
    | Error _ ->
      Server.respond_string ~status:`Bad_request ~body:"Invalid GraphQL query" ()

  let irmin_js_handler address =
    Server.respond_string
      ~status:`OK
      ~headers:(Cohttp.Header.of_list [("Content-Type", "text/javacript")])
      ~body:(irmin_js
      ^ Printf.sprintf
          "\n\n//Generated by Irmin_web\nlet ir = new Irmin(\"%s\");\n" address
      ) ()

  let make_html t =
    let inner = Tyxml.Html.Unsafe.data t.html in
    let html = [%html {|
      <html>
        <head>
          <meta charset="utf-8">
          <title>|}(Html.txt t.title){|</title>
          <link rel="stylesheet" href="/static/css/main.css" />
          <script src="/irmin.js">//</script>
        </head>
        <body>
          |}[inner]{|
          <script src="/static/js/main.js">//</script>
        </body>
      </html>
    |}] in
    let buffer = Buffer.create 64 in
    let fmt = Format.formatter_of_buffer buffer in
    Tyxml.Html.pp () fmt html;
    Buffer.contents buffer

  let callback t graphql_address address html _conn req body =
    let uri = Cohttp_lwt.Request.uri req in
    match Uri.path uri with
    | "/graphql" -> graphql t graphql_address req body
    | "/irmin.js" -> irmin_js_handler address
    | "/static/js/main.js" ->
        let headers = Cohttp.Header.of_list [("Content-Type", "text/javascript")] in
        Server.respond_string ~status:`OK ~headers ~body:t.js ()
    | "/static/css/main.css" ->
        let headers = Cohttp.Header.of_list [("Content-Type", "text/css")] in
        Server.respond_string ~status:`OK ~headers ~body:t.css ()
    | "/" ->
        let headers = Cohttp.Header.of_list [("Content-Type", "text/html")] in
        Server.respond_string ~status:`OK ~headers ~body:html ()
    | _ -> Server.respond_string ~status:`Not_found ~body:"Not found" ()

  let configure addr port = function
    | None ->
        Conduit_lwt_unix.init ~src:addr () >|= fun ctx ->
        ctx, `TCP (`Port port)
    | Some (`Certificate crt, `Key key) ->
        let tls_server_key = `TLS (`Crt_file_path crt, `Key_file_path key, `No_password) in
        Conduit_lwt_unix.init ~src:addr ~tls_server_key () >|= fun ctx ->
        ctx, `TLS (`Crt_file_path crt, `Key_file_path key, `No_password, `Port port)


  let run ?ssl ?(addr = "localhost") ?(port = 8080) t =
    let graphql_port = port + 1 in
    let address = Printf.sprintf "http://%s:%d/graphql" addr port in
    let graphql_address =
      Uri.of_string @@ Printf.sprintf "http://localhost:%d/graphql" graphql_port
    in
    let html = make_html t in
    let callback = callback t graphql_address address html in
    configure addr port ssl >>= fun (ctx, mode) ->
    let ctx = Cohttp_lwt_unix.Net.init ~ctx () in
    let server = Server.make ~callback () in
    Lwt.async (fun () -> start_graphql_server t graphql_port);
    Server.create ~ctx ~mode server
end
