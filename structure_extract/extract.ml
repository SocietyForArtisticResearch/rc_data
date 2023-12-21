let list_directory path =
  try Array.to_list (Sys.readdir path) with Sys_error _ -> []

let is_directory path = Sys.file_exists path && Sys.is_directory path

(* handle (string * string list *)
(* expid * weave * screens *)
(* so we want to create a dict, with expid, containing a list of pages, containing a list of
   0 : { normal, resized ,compressed }
   1 : { normal, resized ,compressed }
*)

let generate_structure root =
  (* Get expositionIDs - assume these are folders under root *)
  let expositionIDs =
    List.filter
      (fun x -> is_directory (Filename.concat root x))
      (list_directory root)
  in

  (* For each folder with ExpositionID, list its weave folders *)
  let weaves =
    List.map
      (fun expo ->
        let path = Filename.concat root expo in
        let weaves =
          List.filter
            (fun x -> is_directory (Filename.concat path x))
            (list_directory path)
        in

        (* For each weavefolder with weave id, list its files *)
        let screenshots =
          List.map
            (fun weave ->
              let weave_path = Filename.concat path weave in
              let urls = list_directory weave_path in
              (weave, urls))
            weaves
        in
        (expo, screenshots))
      expositionIDs
  in
  weaves

type image_type =
  | Compressed of int * int * int
  | Original of int
  | Resized of int * int * int

let is_compressed_withid arg = function
  | Compressed (id, _, _) -> id = arg
  | _ -> false

let is_original_withid arg = function Original id -> id = arg | _ -> false

let is_resized_withid arg = function
  | Resized (id, _, _) -> id = arg
  | _ -> false

let compressed id w h = Compressed (id, w, h)
let resized id w h = Resized (id, w, h)

let rec collect_until f max n =
  if n > max then []
  else
    let result = f n in
    match result with
    | Some x -> (string_of_int n, x) :: collect_until f max (n + 1)
    | None -> []

type file_name = Filename of string

let construct_url image_t =
  let map_triple f (x, y, z) = (f x, f y, f z) in
  match image_t with
  | Original id -> Filename ((id |> string_of_int) ^ ".png")
  | Compressed (id, w, h) ->
      (id, w, h) |> map_triple string_of_int |> fun (x, y, z) ->
      Filename (x ^ "-" ^ y ^ "x" ^ z ^ "-compressed.jpg")
  | Resized (id, w, h) ->
      (id, w, h) |> map_triple string_of_int |> fun (x, y, z) ->
      Filename (x ^ "-" ^ y ^ "x" ^ z ^ ".jpg")

let encode_file (Filename url) = `String url
let encode_file_of_imaget image_t = image_t |> construct_url |> encode_file

let encode_all lst =
  let collect_id arg =
    let comp = List.find_opt (is_compressed_withid arg) lst in
    let norm = List.find_opt (is_original_withid arg) lst in
    let res = List.find_opt (is_resized_withid arg) lst in
    match (comp, norm, res) with
    | Some c, Some ori, Some res ->
        Some
          (`Assoc
            [
              ("compressed", encode_file_of_imaget c);
              ("original", encode_file_of_imaget ori);
              ("resized", encode_file_of_imaget res);
            ])
    | _ -> None
  in
  collect_until collect_id 256 0 |> fun x -> `Assoc x

let fileUrlParser url =
  let open Angstrom in
  let is_digit = function '0' .. '9' -> true | _ -> false in

  let int_parser = take_while1 is_digit >>| int_of_string in

  let dash = char '-' in
  let x_char = char 'x' in
  let compressed_suffix = string "compressed" in
  let jpg_suffix = string ".jpg" in
  let png_suffix = string ".png" in

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
  let original_parser =
    int_parser <* png_suffix >>| fun id -> Original id
    (* Assuming default values for width and height *)
  in

  (* 0.png *)
  let image_parser =
    choice [ compressed_parser; original_parser; resized_parser ]
  in
  parse_string image_parser ~consume:Consume.All url

(* let test_data =
   [
     ( "123456",
       [
         ( "78910",
           [
             "0.png";
             "0-200x400.jpg";
             "0-200x400-compressed.jpg";
             "1.png";
             "1-200x400.jpg";
             "1-200x400-compressed.jpg";
           ] );
       ] );
   ] *)

let map_tree_to_json (tree : (string * (string * string list) list) list) :
    string =
  let fromFile (file : string) : image_type option =
    file |> fileUrlParser |> Result.to_option
  in
  let fromFiles (files : string list) : Yojson.Basic.t =
    files |> List.filter_map fromFile |> encode_all
  in
  let fromPage ((pageId, filenames) : string * string list) :
      string * Yojson.Basic.t =
    (pageId, fromFiles filenames)
  in
  let fromExpo ((expId, pages) : string * (string * string list) list) :
      string * Yojson.Basic.t =
    (expId, `Assoc (List.map fromPage pages))
  in
  `Assoc (List.map fromExpo tree) |> Yojson.Basic.to_string

let write_string_to_file filename content =
  let channel = open_out filename in
  output_string channel content;
  close_out channel

let () =
  let open Printf in
  if Array.length Sys.argv < 2 then (
    printf "Usage: %s <path_to_root_folder>\n" Sys.argv.(0);
    exit 1)
  else
    let root = Sys.argv.(1) in
    let structure = generate_structure root in
    structure |> map_tree_to_json |> write_string_to_file "struct.json"
