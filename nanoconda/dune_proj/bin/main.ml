(*
msg type: ADD, DELETE, MODIFY
msg len: 
sequence context: 
payload fields:
*)

(* module Bruh = struct *)
type enum_order = ADD | DELETE | MODIFY
(* end *)

type order = {
  t: enum_order
}

type side = Buy | Sell

type add = {
  order_id : int64;
  side : side;
  price : int64;
  qty : int32;
}

let _string_of_type_enum = function
  | ADD -> "add";
  | DELETE -> "delete";
  | MODIFY -> "modify"

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

