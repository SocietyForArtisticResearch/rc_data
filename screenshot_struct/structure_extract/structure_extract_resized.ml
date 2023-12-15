open Printf

let list_directory path =
  try Array.to_list (Sys.readdir path) with Sys_error _ -> []

let is_directory path = Sys.file_exists path && Sys.is_directory path

let generate_structure root =
  (* Get expositionIDs - assume these are folders under root *)
  let expositionIDs =
    List.filter
      (fun x -> is_directory (Filename.concat root x))
      (list_directory root)
  in

  (* For each expositionID, list its weaves *)
  let weaves =
    List.map
      (fun expo ->
        let path = Filename.concat root expo in
        let weaves =
          List.filter
            (fun x -> is_directory (Filename.concat path x))
            (list_directory path)
        in

        (* For each weave, list its PNGs *)
        let screenshots =
          List.map
            (fun weave ->
              let weave_path = Filename.concat path weave in
              let pngs =
                List.filter
                  (fun x -> Filename.check_suffix x ".png")
                  (list_directory weave_path)
              in
              (weave, pngs))
            weaves
        in
        (expo, screenshots))
      expositionIDs
  in
  weaves

(* let print_as_json structure =
   printf "{\n";
   List.iter
     (fun (expo, weaves) ->
       printf "  \"%s\": {\n" expo;
       List.iter
         (fun (weave, pngs) ->
           printf "    \"%s\": [" weave;
           printf "%s"
             (String.concat ", "
                (List.map (fun png -> sprintf "\"%s\"" png) pngs));
           printf "],\n")
         weaves;
       printf "  },\n")
     structure;
   printf "}\n" *)

let print_as_json structure =
  let join_with f lst = String.concat ",\n" (List.map f lst) in

  let print_weave (weave, pngs) =
    sprintf "    \"%s\": [%s]" weave
      (String.concat ", " (List.map (fun png -> sprintf "\"%s\"" png) pngs))
  in

  printf "{\n";
  printf "%s"
    (join_with
       (fun (expo, weaves) ->
         sprintf "  \"%s\": {\n%s\n  }" expo (join_with print_weave weaves))
       structure);
  printf "\n}\n"

let () =
  if Array.length Sys.argv < 2 then (
    printf "Usage: %s <path_to_root_folder>\n" Sys.argv.(0);
    exit 1)
  else
    let root = Sys.argv.(1) in
    root |> generate_structure |> print_as_json

(*
  structure is as follows
0-450x346-compressed.jpg        0-600x462-compressed.jpg        0.png
0-450x346.jpg                   0-600x462.jpg 
*)

type file =
  | Compressed of { id : int; w : int; h : int }
  | Resized of { id : int; w : int; h : int }
  | Normal of { id : int }

let debug label s =
  print_endline label;
  print_endline s;
  s

let fromUrlToStr url =
  let regex = Str.regexp {|\([0-9]+\)-\([0-9]+\)x\([0-9]+\)-compressed\.jpg|} in
  let regex2 = Str.regexp {|\([0-9]+\)-\([0-9]+\)x\([0-9]+\)\.jpg|} in
  let regex3 = Str.regexp {|\([0-9]+\)\.png|} in
  let result =
    if Str.string_match regex url 0 then
      Some
        (Compressed
           {
             id = Str.matched_group 0 url |> debug "0" |> int_of_string;
             w = Str.matched_group 1 url |> debug "1" |> int_of_string;
             h = Str.matched_group 2 url |> debug "2" |> int_of_string;
           })
    else if Str.string_match regex2 url 0 then
      Some
        (Resized
           {
             id = Str.matched_group 0 url |> int_of_string;
             w = Str.matched_group 1 url |> int_of_string;
             h = Str.matched_group 2 url |> int_of_string;
           })
    else if Str.string_match regex3 url 0 then
      Some (Normal { id = Str.matched_group 0 url |> int_of_string })
    else None
  in
  result

(* let fromUrlToStr url =
   let regex = Str.regexp {|\([0-9]+\)-\([0-9]+\)x\([0-9]+\)-compressed\.jpg|} in
   let regex2 = Str.regexp {|\([0-9]+\)-\([0-9]+\)x\([0-9]+\)\.jpg|} in
   let regex3 = Str.regexp {|\([0-9]+\)\.png|} in
   let result =
     if Str.string_match regex url 0 then
       Some
         (Compressed
            {
              id = Str.matched_group 0 url |> debug "0" |> int_of_string;
              w = Str.matched_group 1 url |> debug "1" |> int_of_string;
              h = Str.matched_group 2 url |> debug "2" |> int_of_string;
            })
     else if Str.string_match regex2 url 0 then
       Some
         (Resized
            {
              id = Str.matched_group 0 url |> int_of_string;
              w = Str.matched_group 1 url |> int_of_string;
              h = Str.matched_group 2 url |> int_of_string;
            })
     else if Str.string_match regex3 url 0 then
       Some (Normal { id = Str.matched_group 0 url |> int_of_string })
     else None
   in
   result *)

type image_type =
  | Compressed of int * int * int
  | Normal of int
  | Resized of int * int * int

let fileUrlParser url =
  let open Angstrom in
  let is_digit = function '0' .. '9' -> true | _ -> false in

  let int_parser = take_while1 is_digit >>| int_of_string in

  let dash = char '-' in
  let x_char = char 'x' in
  let compressed_suffix = string "compressed" in
  let jpg_suffix = string ".jpg" in
  let png_suffix = string ".png" in

  let compressed id w h = Compressed (id, w, h) in
  let resized id w h = Resized (id, w, h) in

  let compressed_parser =
    return compressed <*> int_parser <* dash <*> int_parser <* x_char
    <*> int_parser <* dash <* compressed_suffix <* jpg_suffix
  in

  (* 0-100x300-compressed.jpg 
  *)
  let resized_parser =
    return resized <*> int_parser <* dash <*> int_parser <* x_char
    <*> int_parser <* jpg_suffix
  in

  (* 0-100x300.jpg *)
  let normal_parser =
    int_parser <* png_suffix >>| fun id -> Normal id
    (* Assuming default values for width and height *)
  in

  (* 0.png *)
  let image_parser =
    choice [ compressed_parser; normal_parser; resized_parser ]
  in
  parse_string image_parser ~consume:Consume.All url
