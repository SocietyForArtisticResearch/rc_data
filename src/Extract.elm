module Extract exposing (..)

import Json.Decode
import ParsedExposition
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.File as File
import Posix.IO.Process as Proc


parseJson : Result String String -> IO ()
parseJson json =
    case json of
        Ok str ->
            let
                result =
                    Json.Decode.decodeString ParsedExposition.parsePythonExposition str
            in
            case result of
                Ok expo ->
                    expo
                        |> ParsedExposition.transformStructure
                        |> ParsedExposition.getText
                        |> File.writeContentsTo "text.txt"

                Err e ->
                    Proc.print <| Json.Decode.errorToString e

        Err e ->
            Proc.print <| "there was an error loading the file" ++ e


program : Process -> IO ()
program process =
    File.contentsOf "data/1723425/data.json"
        |> IO.andThen parseJson
