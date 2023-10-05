module Main exposing (program)

import Dict exposing (Dict)
import EnrichedResearch
import Json.Decode
import Json.Encode
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.File as File
import Posix.IO.Process as Proc
import Research exposing (Research)
import Toc


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
onlyId : Research r -> String
onlyId research =
    research.id |> String.fromInt


decode : Json.Decode.Decoder (List Research.Res)
decode =
    Json.Decode.list Research.decoder


handleFile : ( Result String String, Result String String ) -> IO ()
handleFile ( contents, tocs_res ) =
    case ( contents, tocs_res ) of
        ( Ok expJson, Ok tocsJson ) ->
            handleJson ( Json.Decode.decodeString decode expJson, Json.Decode.decodeString Toc.decode tocsJson )

        ( Err e, _ ) ->
            Proc.print ("file error with expositions" ++ e)

        ( _, Err e ) ->
            Proc.print ("file error with tocs" ++ e)


handleJson : ( Result Json.Decode.Error (List (Research r)), Result Json.Decode.Error (List Toc.ExpositionToc) ) -> IO ()
handleJson ( expJson, tocsJson ) =
    case ( expJson, tocsJson ) of
        ( Ok exps, Ok tocs ) ->
            writeKeywordAndEnriched exps tocs

        ( Err e, _ ) ->
            Proc.print <| "json error" ++ Json.Decode.errorToString e

        ( _, Err e ) ->
            Proc.print <| "json error" ++ Json.Decode.errorToString e


writeKeywordAndEnriched : List (Research r) -> List Toc.ExpositionToc -> IO ()
writeKeywordAndEnriched lst tocs =
    let
        kwSet =
            lst |> Research.keywordSet

        kwsJson =
            kwSet |> Research.encodeSet |> Json.Encode.encode 0

        tocDict =
            tocs |> List.map (\t -> ( t.expoId, t )) |> Dict.fromList

        enriched =
            EnrichedResearch.enrich tocDict lst kwSet

        enrichedJson =
            Json.Encode.encode 0 (Json.Encode.list EnrichedResearch.encodeResearchWithKeywords enriched)
    in
    IO.combine
        [ File.writeContentsTo "keywords.json" kwsJson
        , File.writeContentsTo "enriched.json" enrichedJson
        ]
        |> IO.map (always ())


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
        |> IO.andThen
            (\int_res_json ->
                File.contentsOf "toc.json"
                    |> IO.andThen
                        (\toc_json ->
                            IO.return ( int_res_json, toc_json )
                        )
            )
        |> IO.andThen handleFile



-- abstract_with_keywords : List Keyword -> Research -> Research
