module EnrichedResearch exposing (..)

import Array exposing (Array)
import Date exposing (Date)
import Element exposing (Element, text)
import Element.Font as Font
import Json.Decode
import Json.Encode
import KeywordString exposing (KeywordString)
import Regex
import Research exposing (Author, ExpositionID, Portal, PublicationStatus, Research, publicationstatus)
import WorkerTypes


type alias ResearchWithKeywords =
    { id : ExpositionID
    , title : String
    , keywords : List KeywordString
    , created : String
    , author : Author
    , issueId : Maybe Int
    , publicationStatus : PublicationStatus -- should be string?
    , publication : Maybe Date
    , thumbnail : Maybe String
    , abstract : Maybe String
    , defaultPage : String
    , portals : List Portal
    , abstractWithKeywords : AbstractWithKeywords
    }


researchWithKeywords : Research -> AbstractWithKeywords -> ResearchWithKeywords
researchWithKeywords expo kwAbstract =
    { id = expo.id
    , title = expo.title
    , keywords = expo.keywords
    , created = expo.created
    , author = expo.author
    , issueId = expo.issueId
    , publicationStatus = expo.publicationStatus
    , publication = expo.publication
    , thumbnail = expo.thumbnail
    , abstract = expo.abstract
    , defaultPage = expo.defaultPage
    , portals = expo.portals
    , abstractWithKeywords = kwAbstract
    }


enrich : List Research -> Research.KeywordSet -> List ResearchWithKeywords
enrich lst kwSet =
    let
        kwList =
            kwSet |> Research.toList |> List.map (Research.kwName >> KeywordString.fromString)

        toResearchWithKw exp =
            fancyAbstract kwList exp |> researchWithKeywords exp
    in
    lst |> List.map toResearchWithKw


encodeResearchWithKeywords : ResearchWithKeywords -> Json.Encode.Value
encodeResearchWithKeywords exp =
    let
        int =
            Json.Encode.int

        string =
            Json.Encode.string

        list =
            Json.Encode.list

        maybeAppend x xs =
            case x of
                Just v ->
                    v :: xs

                Nothing ->
                    xs

        issueId =
            exp.issueId
                |> Maybe.map
                    (\id ->
                        ( "id", int id )
                    )

        publication =
            exp.publication
                |> Maybe.map
                    (\p ->
                        ( "publication", int (Date.toRataDie p) )
                    )

        thumbnail =
            exp.thumbnail
                |> Maybe.map
                    (\t ->
                        ( "thumbnail", string t )
                    )

        abstract =
            exp.abstract
                |> Maybe.map
                    (\a ->
                        ( "abstract", string a )
                    )
    in
    Json.Encode.object
        ([ ( "type", string "exposition" )
         , ( "id", int exp.id )
         , ( "created", string exp.created )
         , ( "title", string exp.title )
         , ( "keywords", list string (List.map KeywordString.toString exp.keywords) )
         , ( "author", Research.encodeAuthor exp.author )
         , ( "publicationStatus", Research.publicationstatus exp.publicationStatus )
         , ( "defaultPage", string exp.defaultPage )
         , ( "portals", list WorkerTypes.encodePortal exp.portals )
         , ( "abstractWithKeywords", encodeAbstract exp.abstractWithKeywords )
         ]
            |> maybeAppend issueId
            |> maybeAppend publication
            |> maybeAppend thumbnail
            |> maybeAppend abstract
        )



-- Abstract with parsed keywords


type alias AbstractWithKeywords =
    List AbstractSpan


type AbstractSpan
    = AbsKw String -- A keyword
    | AbsText String -- Normal text


encodeAbstractSpan : AbstractSpan -> Json.Encode.Value
encodeAbstractSpan span =
    case span of
        AbsKw s ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "AbsKw" )
                , ( "string", Json.Encode.string s )
                ]

        AbsText s ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "AbsText" )
                , ( "string", Json.Encode.string s )
                ]


decodeAbstractSpan : Json.Decode.Decoder AbstractSpan
decodeAbstractSpan =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
            (\t ->
                case t of
                    "AbsKw" ->
                        Json.Decode.map AbsKw
                            (Json.Decode.field "string" Json.Decode.string)

                    "AbsText" ->
                        Json.Decode.map AbsText
                            (Json.Decode.field "string" Json.Decode.string)

                    _ ->
                        Json.Decode.fail "abstract decoder expected a AbsKw or AbsText"
            )


encodeAbstract : AbstractWithKeywords -> Json.Encode.Value
encodeAbstract abstract =
    Json.Encode.list encodeAbstractSpan abstract


isKwInAbstract : String -> KeywordString -> Bool
isKwInAbstract abstract kws =
    let
        kw =
            " " ++ KeywordString.toString kws ++ "[!.,? ;:]"

        maybeRegex =
            Regex.fromString kw

        regex =
            Maybe.withDefault Regex.never maybeRegex
    in
    Regex.contains regex abstract


sliceAbstract : Maybe String -> Int -> String
sliceAbstract abs max =
    let
        isGreaterThan : Int -> Int -> Bool
        isGreaterThan mx value =
            value > mx

        abstract =
            Maybe.withDefault "" abs

        fullStopsInAbstract =
            String.indexes "." abstract

        fullStopsAfterMax =
            List.filter (isGreaterThan max) fullStopsInAbstract

        firstFullStopAfterMax =
            Maybe.withDefault max (List.head fullStopsAfterMax)
    in
    String.left (firstFullStopAfterMax + 1) abstract


findKwsInAbstract : List KeywordString -> String -> ( List Int, List String )
findKwsInAbstract kws shortAbstract =
    let
        kwsInAbstract =
            List.map (findKwInAbstract shortAbstract) kws

        kwsSorted =
            List.drop 1 (List.sort kwsInAbstract)
    in
    List.unzip kwsSorted


findKwInAbstract : String -> KeywordString -> ( Int, String )
findKwInAbstract abstract kw =
    let
        extractIndex : Maybe Regex.Match -> Int
        extractIndex match =
            case match of
                Nothing ->
                    0

                Just m ->
                    m.index

        keyword =
            KeywordString.toString kw

        key =
            " " ++ keyword ++ "[!.,? ;:]"

        maybeRegex =
            Regex.fromString key

        regex =
            Maybe.withDefault Regex.never maybeRegex

        finds =
            Regex.find regex abstract

        first =
            List.head finds

        kwStart =
            extractIndex first
    in
    ( kwStart, keyword )


isSubkeyword : List String -> Int -> Bool
isSubkeyword keywords index =
    let
        kws =
            Array.fromList keywords

        kw =
            Maybe.withDefault "" (Array.get index kws)

        first =
            Array.slice 0 index kws

        second =
            Array.slice (index + 1) (Array.length kws) kws

        arr =
            Array.append first second

        bools =
            Array.map (String.contains kw) arr

        list =
            Array.toList bools
    in
    List.member True list


fancyAbstract : List KeywordString -> Research -> AbstractWithKeywords
fancyAbstract allKeywords research =
    let
        abstractMax =
            300

        shortAbstract =
            sliceAbstract research.abstract abstractMax

        kws =
            List.filter (isKwInAbstract shortAbstract) allKeywords

        foundKws =
            findKwsInAbstract kws shortAbstract

        abstractIndexes =
            Tuple.first foundKws

        abstractKeywords =
            Tuple.second foundKws

        series =
            List.range 0 (List.length abstractKeywords)

        subKeywords =
            List.map (isSubkeyword abstractKeywords) series

        kwina =
            List.map (parsedAbstract abstractIndexes subKeywords abstractKeywords shortAbstract) series

        abstract =
            List.concat kwina
    in
    abstract


parsedAbstract : List Int -> List Bool -> List String -> String -> Int -> AbstractWithKeywords
parsedAbstract indexes subkeywords keywords abstract which =
    let
        kwsLength =
            List.length keywords

        idx =
            Array.fromList indexes

        kws =
            Array.fromList keywords

        subs =
            Array.fromList subkeywords

        isSub =
            Maybe.withDefault False (Array.get which subs)

        firstk =
            Maybe.withDefault "-1" (Array.get 0 kws)
    in
    if which == 0 then
        -- first kw
        let
            k =
                Maybe.withDefault -1 (Array.get which idx)

            -- I think this happens when the abstact is a white space
            -- this matches somehow the "?" keyword, which is then dropped creating an empty list
            keyw =
                Maybe.withDefault "!!! This is an empty list !!!" (Array.get which kws)

            kwlength =
                String.length keyw

            prevk =
                Maybe.withDefault 0 (Array.get (which - 1) idx)

            prevkeyw =
                Maybe.withDefault "" (Array.get (which - 1) kws)

            prevkwlength =
                String.length prevkeyw

            sliceLeft =
                String.slice (prevk + prevkwlength) (k + 1) abstract
        in
        if isSub == True then
            [ AbsText sliceLeft ]

        else
            [ AbsText sliceLeft, AbsKw keyw ]

    else if which == kwsLength then
        -- append abstract end
        let
            k =
                Maybe.withDefault -1 (Array.get (which - 1) idx)

            keyw =
                Maybe.withDefault "-1" (Array.get (which - 1) kws)

            kwlength =
                String.length keyw

            sliceRight =
                String.dropLeft (k + kwlength + 1) abstract
        in
        [ AbsText sliceRight ]

    else
        -- slice abstract snippet + insert kw link
        let
            k =
                Maybe.withDefault -1 (Array.get which idx)

            keyw =
                Maybe.withDefault ">>>>>>>>" (Array.get which kws)

            kwlength =
                String.length keyw

            prevk =
                Maybe.withDefault 0 (Array.get (which - 1) idx)

            prevkeyw =
                Maybe.withDefault "" (Array.get (which - 1) kws)

            prevkwlength =
                String.length prevkeyw

            sliceLeft =
                String.slice (prevk + prevkwlength + 1) (k + 1) abstract

            strToKw =
                stringToKeyword keyw
        in
        if isSub == True then
            [ AbsText sliceLeft ]

        else
            [ AbsText sliceLeft, AbsKw keyw ]


gray : Element.Color
gray =
    Element.rgb 0.5 0.5 0.5


stringToKeyword : String -> Element msg
stringToKeyword str =
    Element.link [ Font.size 12, Font.color gray, Font.underline ] <|
        { label = Element.text str
        , url = "/#/research/search/list?author&keyword=" ++ str ++ " "
        }



-- makeSnippet : List Int -> List Bool -> List String -> String -> Int -> List (Element msg)
-- makeSnippet indexes subkeywords keywords abstract which =
--     let
--         kwsLength =
--             List.length keywords
--         idx =
--             Array.fromList indexes
--         kws =
--             Array.fromList keywords
--         subs =
--             Array.fromList subkeywords
--         isSub =
--             Maybe.withDefault False (Array.get which subs)
--         firstk =
--             Maybe.withDefault "-1" (Array.get 0 kws)
--     in
--     if which == 0 then
--         -- first kw
--         let
--             k =
--                 Maybe.withDefault -1 (Array.get which idx)
--             -- I think this happens when the abstact is a white space
--             -- this matches somehow the "?" keyword, which is then dropped creating an empty list
--             keyw =
--                 Maybe.withDefault "!!! This is an empty list !!!" (Array.get which kws)
--             kwlength =
--                 String.length keyw
--             prevk =
--                 Maybe.withDefault 0 (Array.get (which - 1) idx)
--             prevkeyw =
--                 Maybe.withDefault "" (Array.get (which - 1) kws)
--             prevkwlength =
--                 String.length prevkeyw
--             sliceLeft =
--                 String.slice (prevk + prevkwlength) (k + 1) abstract
--             strToKw =
--                 stringToKeyword keyw
--         in
--         if isSub == True then
--             [ text sliceLeft ]
--         else
--             [ text sliceLeft, strToKw ]
--     else if which == kwsLength then
--         -- append abstract end
--         let
--             k =
--                 Maybe.withDefault -1 (Array.get (which - 1) idx)
--             keyw =
--                 Maybe.withDefault "-1" (Array.get (which - 1) kws)
--             kwlength =
--                 String.length keyw
--             sliceRight =
--                 String.dropLeft (k + kwlength + 1) abstract
--         in
--         [ text sliceRight ]
--     else
--         -- slice abstract snippet + insert kw link
--         let
--             k =
--                 Maybe.withDefault -1 (Array.get which idx)
--             keyw =
--                 Maybe.withDefault ">>>>>>>>" (Array.get which kws)
--             kwlength =
--                 String.length keyw
--             prevk =
--                 Maybe.withDefault 0 (Array.get (which - 1) idx)
--             prevkeyw =
--                 Maybe.withDefault "" (Array.get (which - 1) kws)
--             prevkwlength =
--                 String.length prevkeyw
--             sliceLeft =
--                 String.slice (prevk + prevkwlength + 1) (k + 1) abstract
--             strToKw =
--                 stringToKeyword keyw
--         in
--         if isSub == True then
--             [ text sliceLeft ]
--         else
--             [ text sliceLeft, strToKw ]
