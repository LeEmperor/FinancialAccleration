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

let _parse_msg (c : cursor) : msg result = 
  let msg_type = read_u16 c in


  Ok (
    Unknown {msg_type; raw}
  )


let _makeAdd = 
  ()

let () = 
  print_endline "Bonjour, das Welt!";

  let _add_inst : enum_order = ADD in
  let _del_inst : enum_order = DELETE in
  let _mod_inst : enum_order = MODIFY in
  let bruh : string = _string_of_type_enum _del_inst in
  Printf.printf "mapped: %s\n" bruh;

  ()

