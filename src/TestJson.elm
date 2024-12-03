module TestJson exposing (program)

import Json.Decode as JD
import Json.Encode as JE
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.File as File
import Posix.IO.Process as Proc
import ParsedExposition


testJsonFile =
    "tests/test1.json"


program : Process -> IO ()
program process =
    File.contentsOf testJsonFile
        |> IO.andThen
            (\result ->
                case result of
                    Err e -> 
                        Proc.print "sorry couldn't laod the file"

                    Ok contents -> 
                        let
                            decoded =
                                JD.decodeString decodeExposition contents
                        in
                        case decoded of
                            Ok _ ->
                                Proc.print "It worked"

                            Err e ->
                                Proc.print ("sorry it failed: " ++ JD.errorToString e)
            )

decodeExposition : JD.Decoder String
decodeExposition = 
    JD.succeed "fyucking great"