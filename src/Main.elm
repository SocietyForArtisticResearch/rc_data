module Main exposing (program)

import Dict exposing (Dict)
import EnrichedResearch
import Json.Decode
import Json.Encode
import Posix.IO as IO exposing (IO, Process)
import Posix.IO.File as File
import Posix.IO.Process as Proc
import Research exposing (Research)
import Screenshots
import Toc


rc_json : String
rc_json =
    "internal_research.json"



-- rc_json = "test_connect.json"


onlyId : Research r -> String
onlyId research =
    research.id |> String.fromInt


decode =
    Json.Decode.list Research.decoder


handleFile : ( Result String String, Result String String, Result String String ) -> IO ()
handleFile ( contents, tocs_res, scr_json ) =
    case ( contents, tocs_res, scr_json ) of
        ( Ok expJson, Ok tocsJson, Ok scrJson ) ->
            handleJson ( Json.Decode.decodeString decode expJson, Json.Decode.decodeString Toc.decode tocsJson, Json.Decode.decodeString Screenshots.decodeAll scrJson )

        ( Err e, _, _ ) ->
            Proc.print ("file error with expositions" ++ e)

        ( _, Err e, _ ) ->
            Proc.print ("file error with tocs" ++ e)

        ( _, _, Err e ) ->
            Proc.print ("file error with tocs" ++ e)


handleJson :
    ( Result Json.Decode.Error (List (Research r))
    , Result Json.Decode.Error (List Toc.ExpositionToc)
    , Result Json.Decode.Error Screenshots.RCScreenshots
    )
    -> IO ()
handleJson ( expJson, tocsJson, screenJson ) =
    case ( expJson, tocsJson, screenJson ) of
        ( Ok exps, Ok tocs, Ok screens ) ->
            writeKeywordAndEnriched exps tocs screens

        ( Err e, _, _ ) ->
            Proc.print <| "exps json error" ++ Json.Decode.errorToString e

        ( _, Err e, _ ) ->
            Proc.print <| "tocs json error" ++ Json.Decode.errorToString e

        ( _, _, Err e ) ->
            Proc.print <| "screenshot json error" ++ Json.Decode.errorToString e


writeKeywordAndEnriched : List (Research r) -> List Toc.ExpositionToc -> Screenshots.RCScreenshots -> IO ()
writeKeywordAndEnriched lst tocs screens =
    let
        kwSet =
            lst |> Research.keywordSet

        kwsJson =
            kwSet |> Research.encodeSet |> Json.Encode.encode 0

        tocDict =
            tocs |> List.map (\t -> ( t.expoId, t )) |> Dict.fromList

        enriched =
            EnrichedResearch.enrich tocDict lst kwSet screens

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


{-| This is the entry point, you can think of it as `main` in normal Elm applications.
-}
program : Process -> IO ()
program process =
    File.contentsOf rc_json
        |> IO.andThen
            (\int_res_json ->
                File.contentsOf "toc.json"
                    |> IO.andThen
                        (\toc_json ->
                            File.contentsOf "screenshots/screenshots.json"
                                |> IO.andThen
                                    (\scr_json ->
                                        IO.return ( int_res_json, toc_json, scr_json )
                                    )
                        )
            )
        |> IO.andThen handleFile



-- abstract_with_keywords : List Keyword -> Research -> Research
