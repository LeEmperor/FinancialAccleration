(*
msg type: ADD, DELETE, MODIFY
msg len: 
sequence context: 
payload fields:
*)

(* module Bruh = struct *)
type enum_order = ADD | DELETE | MODIFY | RAW
(* end *)

type order = {
  t: enum_order
}

type side = Buy | Sell

type add = {
  side : side;
  price : int64;
  qty : int32;
}

type del = {
  price: int64;
  qty: int32;
}

type exec = {
  side : side;
  price: int64;
  qty : int32;
}

type msg = 
  | Add of add
  | Del of del
  | Exec of exec
  | Unknown of {enum_order : int; raw : bytes}

let _string_of_type_enum = function
  | ADD -> "add";
  | DELETE -> "delete";
  | MODIFY -> "modify"
  | _ -> "raw"

type parseError =
  | Truncated of string
  | Bad_value of string

type 'a result = ('a, parseError) Stdlib.result

type cursor = {
  buffer: bytes;
  mutable offset: int
}

let print_cursor_buffer (c: cursor) =
  let tmp = Bytes.to_string c.buffer in
  Printf.printf "cursor buffer: ------------------offset: %d----------------\n%s\n" c.offset tmp

let pint (d: int) : unit =
  Printf.printf "int: %d\n" d 

let pchar (c: char) : unit =
  Printf.printf "char: %c\n" c

let pstr (s: string) : unit =
  Printf.printf "string: %s\n" s

let enum_order_of_u8 (b: int) : (enum_order) result =
  match b with
    | 0x41 -> Ok ADD    (* A *)
    | 0x44 -> Ok DELETE (* D *)
    | 0x4D -> Ok MODIFY (* M *)
    | other -> 
        (* pstring "unmatchable msg type of byte: 0x%02X"; *)
        Printf.printf "unmatchable msg type of byte: 0x%02X\n" other;
        Error (Bad_value (Printf.sprintf "unknown msg_type byte: 0x%02X" other))

let parse_msg (c : cursor) : msg result = 
  let msg_type  = Bytes.get_uint8 c.buffer c.offset in
  c.offset <- c.offset + 1;

  let tmp = match enum_order_of_u8 msg_type with
  | Ok ADD ->
      pstr "Add enum matched!";
      Ok (Unknown {enum_order = msg_type; raw = Bytes.empty })
  | Error e -> 
      (* pstring "error on mapping enum from byte"; *)
      Error e 
  | _ -> 
      pstr "fallback on parse_msg, enum was mapped; however no behaviour is based on this enum occuring!";
      Error (Bad_value (Printf.sprintf "unknown enum map match returned, does not signify mapping was invalid"))
  in

  Error (
    Bad_value "bad val string"
  )

  (* Ok ( *)
  (*   Unknown { *)
  (*     enum_order = -1; raw = Bytes.empty *)
  (*   } *)
  (* ) *)


let _makeAdd = 
  ()

let print_parse_error = function
  | Truncated msg -> 
      Printf.printf "Parse error (truncated): %s\n" msg
  | Bad_value msg ->
      Printf.printf "Parse error (bad value): %s\n" msg

let () = 
  (* print_endline "Bonjour, das Welt!"; *)

  let c: cursor = {
    (* buffer = Bytes.of_string "ADMB"; *)
    buffer = Bytes.of_string "B";
    offset = 0;
  } in

  (* let tmp = parse_msg c in *)
  (* let tmp2 = parse_msg c in *)
  (* let tmp3 = parse_msg c in *)
  let tmp4 = parse_msg c in
  let tmp5 = match tmp4 with
    | Ok msg ->
        pstr "bruh"
    | Error e ->
        print_parse_error e
  in

  (* let tmp: char = Bytes.get (Bytes.of_string "test_string") 0 in *)
  (* pchar tmp; *)

  (* print_cursor_buffer c; *)

  ()

