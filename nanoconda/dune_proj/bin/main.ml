(*
msg type: ADD, DELETE, MODIFY
msg len: 
sequence context: 
payload fields:
 *)

(* module Bruh = struct *)
type enum_order = ADD | DELETE | MODIFY
(* end *)

(* type order = { *)
(*   t: enum_order *)
(* } *)

let _string_of_type_enum = function
  | ADD -> "add";
  | DELETE -> "delete";
  | MODIFY -> "modify"

let _makeAdd = 

  ()

let () = 
  print_endline "Bonjour, das Welt!"

  let type_inst = ADD in
  let bruh: string = _string_of_type_enum type_inst in
  Printf.printf "mapped: %s" bruh;

  ()

