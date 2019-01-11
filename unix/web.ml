open Lwt.Infix

module Make(Store: Irmin_graphql.Server.S) = struct
  include Irmin_web.Make(Cohttp_lwt_unix.Server)(Store)

  let run ?(allow_mutations = true) ?ssl ?(addr = "localhost") ?(port = 8080) ~title ~css ~js ~html store =
      let server = config ~allow_mutations ~title ~css ~js ~html store in
      let server = make ~addr ~port server in
      let on_exn _ = () in
      (match ssl with
        | None ->
          Conduit_lwt_unix.init ~src:addr () >|= fun ctx ->
          ctx, (`TCP (`Port port))
        | Some (crt, key) ->
          let tls_server_key = `TLS (`Crt_file_path crt, `Key_file_path key, `No_password) in
          Conduit_lwt_unix.init ~src:addr ~tls_server_key () >|= fun ctx ->
          ctx, `TLS (`Crt_file_path crt, `Key_file_path key, `No_password, `Port port))
      >>= fun (ctx, mode) ->
      let ctx = Cohttp_lwt_unix.Net.init ~ctx () in
      Cohttp_lwt_unix.Server.create server ~ctx ~mode ~on_exn
end
