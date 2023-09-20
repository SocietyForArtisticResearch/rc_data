module Main exposing (program)

import Dict exposing (Dict)
import Json.Decode
import Json.Encode
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.File as File
import Posix.IO.Process as Proc
import Research exposing (Research)
import EnrichedResearch 


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
onlyId : Research r -> String
onlyId research =
    research.id |> String.fromInt


decode : Json.Decode.Decoder (List Research.Res)
decode =
    Json.Decode.list Research.decoder


handleJson : Result String String -> IO ()
handleJson contents =
    contents
        |> Result.andThen
            (Json.Decode.decodeString decode >> Result.mapError Json.Decode.errorToString)
        |> writeKeywordFile



writeKeywordFile : Result error (List (Research r)) -> IO ()
writeKeywordFile result =
    case result of
        Ok lst ->
            let
                kwSet = lst |> Research.keywordSet 

                kwsJson =
                    kwSet |> Research.encodeSet |> Json.Encode.encode 0

                enriched = 
                    EnrichedResearch.enrich lst kwSet 

                enrichedJson =
                    Json.Encode.encode 0 (Json.Encode.list EnrichedResearch.encodeResearchWithKeywords enriched)
            in
            IO.combine
                [ File.writeContentsTo "keywords.json" kwsJson
                , File.writeContentsTo "enriched.json" enrichedJson
                ]
                |> IO.map (always ())

        Err _ ->
            Proc.print "sorry there was an error"


printResult : Result error value -> IO ()
printResult r =
    case r of
        Ok _ ->
            Proc.print "yes"

        Err _ ->
            Proc.print "no"


program : Process -> IO ()
program process =
    File.contentsOf "internal_research.json"
        |> IO.andThen handleJson



-- abstract_with_keywords : List Keyword -> Research -> Research
