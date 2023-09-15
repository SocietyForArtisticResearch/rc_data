module Main exposing (program)

import Dict exposing (Dict)
import Json.Decode
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.File as File
import Posix.IO.Process as Proc
import Research exposing (Research)


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
onlyId : Research -> String
onlyId research =
    research.id |> String.fromInt


decode : Json.Decode.Decoder (List Research)
decode =
    Json.Decode.list Research.decoder


handleJson : Result String String -> IO ()
handleJson contents =
    contents
        |> Result.andThen
            (\str -> Json.Decode.decodeString decode str |> Result.mapError Json.Decode.errorToString)
        |> printResult


printResult r =
    case r of
        Ok _ ->
            Proc.print "yes"

        Err _ ->
            Proc.print "no"


program : Process -> IO ()
program process =
    File.contentsOf "data.json"
        |> IO.andThen handleJson
