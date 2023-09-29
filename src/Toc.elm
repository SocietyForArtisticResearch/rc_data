module Toc exposing (..)

import Json.Decode as Decode
import Json.Decode.Extra exposing (andMap)
import Json.Encode


type alias Id =
    Int


type alias ExpositionToc =
    { expoId : Id
    , weaves : List Weave
    }


type alias Weave =
    { file : String
    , page : Int
    , pageTitle : String
    , url : String
    , weaveSize : Dimensions
    }


type alias Dimensions =
    { height : Int
    , width : Int
    }


pageWithWeaves : ( String, List Weave ) -> ExpositionToc
pageWithWeaves ( idStr, weaves ) =
    { expoId = Maybe.withDefault 0 (String.toInt idStr)
    , weaves = weaves
    }


decodeEntry : Decode.Decoder (List ExpositionToc)
decodeEntry =
    let
        obj : Decode.Decoder (List ( String, List Weave ))
        obj =
            Decode.keyValuePairs (Decode.list decodeWeave)
    in
    -- inverse monad, first concat than map ?
    Decode.list obj
        |> Decode.map (List.concat >> List.map pageWithWeaves)


decodeWeave : Decode.Decoder Weave
decodeWeave =
    Decode.succeed Weave
        |> andMap (Decode.field "file" Decode.string)
        |> andMap (Decode.field "page" (Decode.string |> Decode.map (String.toInt >> Maybe.withDefault 0)))
        |> andMap (Decode.field "page_title" Decode.string)
        |> andMap (Decode.field "url" Decode.string)
        |> andMap (Decode.field "weave_size" decodeDimensions)


decodeDimensions : Decode.Decoder Dimensions
decodeDimensions =
    Decode.succeed Dimensions
        |> andMap (Decode.field "height" Decode.int)
        |> andMap (Decode.field "width" Decode.int)


encodedRoot : List ExpositionToc -> Json.Encode.Value
encodedRoot lst =
    Json.Encode.list encodeEntry lst


encodeEntry : ExpositionToc -> Json.Encode.Value
encodeEntry expoToc =
    Json.Encode.object
        [ ( String.fromInt expoToc.expoId, Json.Encode.list encodeWeave expoToc.weaves )
        ]


encodeWeave : Weave -> Json.Encode.Value
encodeWeave weave =
    Json.Encode.object
        [ ( "file", Json.Encode.string weave.file )
        , ( "page", Json.Encode.int weave.page )
        , ( "page_title", Json.Encode.string weave.pageTitle )
        , ( "url", Json.Encode.string weave.url )
        , ( "weave_size", encodeDimensions weave.weaveSize )
        ]


encodeDimensions : Dimensions -> Json.Encode.Value
encodeDimensions d =
    Json.Encode.object
        [ ( "height", Json.Encode.int d.height )
        , ( "width", Json.Encode.int d.width )
        ]
