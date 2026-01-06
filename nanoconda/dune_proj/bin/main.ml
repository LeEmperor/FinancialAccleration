(*
msg type: ADD, DELETE, MODIFY
msg len: 
sequence context: 
payload fields:
*)

type msg_type_e = ADD | DELETE | MODIFY | RAW

type order = {
  t: msg_type_e 
}

type side_e = Buy | Sell

type add_t = {
  side : side_e;
  price : int64;
  qty : int32;
}

type delete_t = {
  side: side_e;
  price: int64;
  qty: int32;
}

type modify_t = {
  side: side_e;
  price_delta: int64;
  qty_delta: int32;
}

type exec_t = {
  side : side_e;
  price: int64;
  qty : int32;
}

type msg_t = 
  | Add of add_t
  | Delete of delete_t
  | Execute of exec_t
  | Unknown of {code : int; raw : bytes}

let string_of_msg_type_e = function
  | ADD -> "add";
  | DELETE -> "delete";
  | MODIFY -> "modify"
  | _ -> "unmappable msg type"

type parseError =
  | Truncated of string
  | Bad_value of string

type cursor = {
  buffer: bytes;
  mutable offset: int
}

module Result = struct
  type 'a t = ('a, parseError) Stdlib.result

  let ( let* ) r f = match r with
  | Ok x -> f x
  | Error e -> Error e

  let ( let+ )r f = match r with
  | Ok x -> Ok (f x)
  | Error e -> Error e

  let errorf fmt =
    Printf.ksprintf (fun s -> Error (Bad_value s)) fmt
end

let ensure (c: cursor) (n: int) : unit Result.t =
  let remaining = Bytes.length c.buffer - c.offset in
  if remaining >= n then Ok ()
  else Error (Truncated (Printf.sprintf "need %d bytes, have %d remaining" n remaining))

let read_u8 (c: cursor) : int Result.t =
  let open Result in 
  let* () = ensure c 1 in
  let v = Bytes.get_uint8 c.buffer c.offset in
  c.offset <- c.offset + 1;
  Ok v

type 'a result = ('a, parseError) Stdlib.result

let print_cursor_buffer (c: cursor) =
  let tmp = Bytes.to_string c.buffer in
  Printf.printf "cursor buffer: ------------------offset: %d----------------\n%s\n" c.offset tmp

let pint (d: int) : unit =
  Printf.printf "int: %d\n" d 

let pchar (c: char) : unit =
  Printf.printf "char: %c\n" c

let pstr (s: string) : unit =
  Printf.printf "string: %s\n" s

let print_msg_data (m: msg_t) : unit =
  let tmp: unit = match m with
  | Add add ->
      (* pstr "msg variant ADD found" *)
      Printf.printf "ADD msg found with price: %020Ld\n" add.price;
  | Delete del ->
      pstr "msg variant DELETE found"
  | Execute exec ->
      pstr "msg variant EXECUTE found"
  | _ ->
      pstr "default variant found"
  in

  ()

let msg_type_of_u8 (b: int) : (msg_type_e) Result.t =
  match b with
    | 0x41 -> Ok ADD    (* A *)
    | 0x44 -> Ok DELETE (* D *)
    | 0x4D -> Ok MODIFY (* M *)
    (* | other ->  *)
    (*     (* pstring "unmatchable msg type of byte: 0x%02X"; *) *)
    (*     Printf.printf "unmatchable msg type of byte: 0x%02X\n" other; *)
    (*     Error (Bad_value (Printf.sprintf "unknown msg_type byte: 0x%02X" other)) *)
    | other -> Ok RAW

let parse_msg (c : cursor) : msg_t Result.t = 
  let open Result in
  let* byte = read_u8 c in (* c'est un monad *)
  let* msg_type = msg_type_of_u8 byte in

  match msg_type with
  | ADD ->
      Ok (
        Add {
          side = Buy;
          price = 10L;
          qty = 10l;
        }
      )
  | MODIFY ->
      Ok (
        Add {
          side = Buy;
          price = 10L;
          qty = 10l;
        }
      )
  | DELETE ->
      Ok (
        Add {
          side = Buy;
          price = 10L;
          qty = 10l;
        }
      )
  | RAW -> 
      Ok (
        Unknown {
          code = -1;
          raw = Bytes.empty;
        }
      )

let print_parse_error = function
  | Truncated msg -> 
      Printf.printf "Parse error (truncated): %s\n" msg
  | Bad_value msg ->
      Printf.printf "Parse error (bad value): %s\n" msg

let () = 
  (* print_endline "Bonjour, das Welt!"; *)

  let c: cursor = {
    (* buffer = Bytes.of_string "ADMB"; *)
    buffer = Bytes.of_string "A";
    offset = 0;
  } in

  let tmp: msg_t Result.t = parse_msg c in
  let tmp = match tmp with
  | Ok msg ->
      print_msg_data msg
  | Error e ->
      print_parse_error e
  in

  (* let tmp2 = parse_msg c in *)
  (* let tmp3 = parse_msg c in *)
  (* let tmp4 = parse_msg c in *)
  (* let tmp5 = match tmp4 with *)
  (*   | Ok msg -> *)
  (*       pstr "bruh" *)
  (*   | Error e -> *)
  (*       print_parse_error e *)
  (* in *)

  (* let tmp: char = Bytes.get (Bytes.of_string "test_string") 0 in *)
  (* pchar tmp; *)

  (* print_cursor_buffer c; *)

  ()

