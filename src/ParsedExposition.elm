module ParsedExposition exposing
    ( Dimensions
    , EditorType
    , Exposition(..)
    , Page(..)
    , decodeList
    , getText
    , parsePythonExposition
    , pretty
    , transformStructure
    )

import AppUrl
import Color exposing (Color)
import Dict exposing (Dict)
import Html exposing (Html, text)
import Html.Attributes
import Json.Decode as D exposing (Decoder)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as E
import Research exposing (ExpositionID)
import Time exposing (Posix)


type alias Dimensions =
    { x : Int, y : Int, w : Int, h : Int }



-- needs to have tools and other stuff


type Page
    = GraphicalPage PageData
    | BlockPage PageData


pageData : Page -> PageData
pageData p =
    case p of
        GraphicalPage pd ->
            pd

        BlockPage pd ->
            pd


type EditorType
    = Graph
    | Block
    | Text


type PageURL
    = PageURL String


pretty : List Exposition -> Html msg
pretty exps =
    Html.ul [] (List.map prettyExp exps)


prettyExp : Exposition -> Html msg
prettyExp (Exposition data) =
    Html.li [] [ Html.h1 [] [ data.id |> String.fromInt |> text ], Html.ul [] (data.pages |> List.map prettyPage) ]


prettyPage : Page -> Html msg
prettyPage page =
    Html.li []
        [ page |> pageData |> pageId |> printId
        , Html.ul [] (page |> getTools |> List.map prettyTool)
        ]


toolWithColor : String -> Color -> Html msg
toolWithColor name color =
    Html.span [ Html.Attributes.style "color" (Color.toCssString color) ] [ text name ]


prettyTool : Tool -> Html msg
prettyTool tl =
    case tl of
        SimpleTextTool _ ->
            toolWithColor " txt " Color.red

        HtmlTextTool _ ->
            toolWithColor " html " Color.blue

        ImageTool _ ->
            toolWithColor " image tool " Color.brown

        VideoTool _ ->
            toolWithColor " video tool " Color.darkYellow


pageUrlToString : PageURL -> String
pageUrlToString (PageURL u) =
    u


pageUrls : D.Decoder (List PageURL)
pageUrls =
    D.list D.string |> D.map (List.map PageURL)


fetchPageID : PageURL -> Maybe PageID
fetchPageID (PageURL p) =
    p |> String.split "/" |> List.reverse |> List.head |> Maybe.andThen String.toInt


editorType : D.Decoder EditorType
editorType =
    D.string
        |> D.map
            (\str ->
                case str of
                    "weave-block" ->
                        Block

                    "weave-graphical" ->
                        Graph

                    _ ->
                        Graph
            )


type alias PythonOutput =
    { id : Int
    , editorType : EditorType
    , pages : List String
    , toolText : Dict PageId (List Tool)
    , toolHtml : Dict PageId (List Tool)
    , toolImage : Dict PageId (List Tool)
    , toolVideo : Dict PageId (List Tool)
    }


expositionId : Decoder ExpositionID
expositionId =
    D.int


parsePythonExposition : Decoder PythonOutput
parsePythonExposition =
    D.succeed PythonOutput
        |> andMap (D.field "id" expositionId)
        |> andMap (D.field "type" editorType)
        |> andMap (D.field "pages" (D.list D.string))
        |> andMap (D.field "tool-text" (toolText HtmlText))
        |> andMap (D.field "tool-simpletext" (toolText SimpleText))
        |> andMap (D.field "tool-picture" toolImage)
        |> andMap (D.field "tool-video" toolVideo)


combineValues : Dict comparable (List a) -> Dict comparable (List a) -> Dict comparable (List a)
combineValues dictA dictB =
    let
        complete =
            (dictA |> Dict.toList)
                ++ (dictB |> Dict.toList)

        f : ( comparable, List a ) -> Dict comparable (List a) -> Dict comparable (List a)
        f ( key, values ) acc =
            let
                old =
                    Dict.get key acc
            in
            case old of
                Nothing ->
                    Dict.insert key values acc

                Just oldVal ->
                    Dict.insert key (oldVal ++ values) acc
    in
    List.foldl f Dict.empty complete


decodeList : Decoder (List Exposition)
decodeList =
    D.list parsePythonExposition
        |> D.map (List.map transformStructure)


transformStructure : PythonOutput -> Exposition
transformStructure python =
    let
        tls =
            combineValues python.toolHtml python.toolText

        -- idea: maybe exposition should use the dict of pages, instead of transforming into a list?
        pgs =
            tls |> Dict.toList |> List.map (\( id, ts ) -> GraphicalPage (PageData { pageId = id, tools = ts }))
    in
    Exposition { pages = pgs, id = python.id }


getTools : Page -> List Tool
getTools page =
    case page of
        GraphicalPage (PageData pd) ->
            pd.tools

        BlockPage (PageData pd) ->
            pd.tools


toolToText : Tool -> String
toolToText tool =
    case tool of
        SimpleTextTool data ->
            getTextFromData data

        HtmlTextTool data ->
            getTextFromData data

        ImageTool _ ->
            ""

        VideoTool _ ->
            ""



-- TODO: maybe we can do something clever for other tools


getTextFromData : TextData -> String
getTextFromData data =
    data.text


getText : Exposition -> String
getText (Exposition data) =
    let
        foldPage page acc =
            getTools page |> List.map toolToText |> String.concat |> (\catted -> acc ++ catted)
    in
    data.pages |> List.foldl foldPage ""


type alias PageId =
    Int


type PageData
    = PageData
        { pageId : PageId
        , tools : List Tool
        }


pageId : PageData -> PageId
pageId (PageData pd) =
    pd.pageId


tools : PageData -> List Tool
tools (PageData pd) =
    pd.tools


printId : PageId -> Html msg
printId i =
    Html.text ("page id: " ++ String.fromInt i)


extractToolList : Exposition -> List Tool
extractToolList (Exposition data) =
    let
        toolsLstLst =
            data.pages
                |> List.map
                    (\page ->
                        case page of
                            GraphicalPage (PageData pd) ->
                                pd.tools

                            BlockPage (PageData pd) ->
                                pd.tools
                    )
    in
    toolsLstLst
        |> List.concat


type alias ExpositionContents =
    { pages : Page
    , id : ExpositionID
    }


type alias PageID =
    Int


type ToolStyle
    = ToolStyle String



-- Dimensions x y w h


type alias ToolProperties =
    { dimensions : Dimensions
    , style : ToolStyle
    }


toolProperties : Decoder ToolProperties
toolProperties =
    let
        construct dim style =
            { dimensions = dim
            , style = ToolStyle style
            }
    in
    D.map2 construct
        (D.field "dimensions" decodeDimensions)
        (D.field "style" D.string)


decodeDimensions : Decoder Dimensions
decodeDimensions =
    D.list D.int
        |> D.andThen
            (\lst ->
                case lst of
                    [ x, y, w, h ] ->
                        D.succeed { x = x, y = y, w = w, h = h }

                    _ ->
                        D.fail "I expected a list with 4 integers, x y w h"
            )


decodePixelTuple : Decoder ( Int, Int )
decodePixelTuple =
    D.list D.string
        |> D.andThen
            (\lst ->
                case lst of
                    [ x, y ] ->
                        [ x, y ]
                            |> List.map (String.replace "px" "" >> String.toInt)
                            |> List.filterMap identity
                            |> (\lst2 ->
                                    case lst2 of
                                        [ i1, i2 ] ->
                                            D.succeed ( i1, i2 )

                                        _ ->
                                            D.fail "expected two integers with "
                               )

                    _ ->
                        D.fail "expected two px values"
            )


dummyToolProperties : ToolProperties
dummyToolProperties =
    { dimensions = { x = 0, y = 0, w = 0, h = 0 }
    , style = ToolStyle ""
    }


type ToolId
    = ToolId String


type Tool
    = SimpleTextTool TextData
    | HtmlTextTool TextData
    | ImageTool { id : ToolId, toolProperties : ToolProperties, mediaUrl : String }
    | VideoTool VideoData


type alias TextData =
    { toolProperties : ToolProperties
    , html : String
    , text : String
    , id : ToolId
    }


getSize : Tool -> Dimensions
getSize tool =
    case tool of
        SimpleTextTool d ->
            d.toolProperties.dimensions

        HtmlTextTool d ->
            d.toolProperties.dimensions

        ImageTool d ->
            d.toolProperties.dimensions

        VideoTool d ->
            d.toolProperties.dimensions


type alias Url =
    String


type alias VideoData =
    { toolId : ToolId
    , content : Url
    , previewThumb : Url
    , toolProperties : ToolProperties
    }



-- add more


type Exposition
    = Exposition { pages : List Page, id : ExpositionID }


simpletext : ToolId -> String -> String -> Tool
simpletext id html text =
    SimpleTextTool
        { id = id
        , html = html
        , text = text
        , toolProperties = dummyToolProperties
        }


htmlText : ToolId -> String -> String -> Tool
htmlText id html text =
    HtmlTextTool
        { id = id
        , html = html
        , text = text
        , toolProperties = dummyToolProperties
        }


type TextToolType
    = SimpleText
    | HtmlText


toolText : TextToolType -> D.Decoder (Dict PageID (List Tool))
toolText t =
    let
        construct =
            case t of
                SimpleText ->
                    simpletext

                HtmlText ->
                    htmlText

        textTool =
            D.map3
                construct
                (D.field "id" D.string |> D.map ToolId)
                (D.field "content" D.string)
                (D.field "src" D.string)

        pgs =
            D.list textTool
    in
    D.keyValuePairs pgs
        |> D.map
            (\lst ->
                lst
                    |> List.map (Tuple.mapFirst (String.toInt >> Maybe.withDefault 0))
                    |> Dict.fromList
            )


type alias ImageData =
    { toolId : ToolId
    , media : Url
    , toolProperties : ToolProperties
    }


toolImage : D.Decoder (Dict PageID (List Tool))
toolImage =
    let
        imageTool =
            D.map3
                (\id props mediaUrl ->
                    ImageTool
                        { id = id
                        , toolProperties = props
                        , mediaUrl = mediaUrl
                        }
                )
                (D.field "id" D.string |> D.map ToolId)
                toolProperties
                (D.succeed "todo.png")

        pages =
            D.list imageTool
    in
    D.keyValuePairs pages
        |> D.map
            (\lst ->
                lst
                    |> List.map (Tuple.mapFirst (String.toInt >> Maybe.withDefault 0))
                    |> Dict.fromList
            )


toolVideo : D.Decoder (Dict PageID (List Tool))
toolVideo =
    let
        videoTool =
            D.map3
                (\id props mediaUrl ->
                    ImageTool
                        { id = id
                        , toolProperties = props
                        , mediaUrl = mediaUrl
                        }
                )
                (D.field "id" D.string |> D.map ToolId)
                toolProperties
                (D.succeed "todo.png")

        pages =
            D.list videoTool
    in
    D.keyValuePairs pages
        |> D.map
            (\lst ->
                lst
                    |> List.map (Tuple.mapFirst (String.toInt >> Maybe.withDefault 0))
                    |> Dict.fromList
            )
