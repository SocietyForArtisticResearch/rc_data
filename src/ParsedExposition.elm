module ParsedExposition exposing (Dimensions, EditorType, Page, getText, parsePythonExposition, transformStructure)

import AppUrl
import Dict exposing (Dict)
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


type EditorType
    = Graph
    | Block
    | Text


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

    --, toolVideo : Dict PageId (List Tool)
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


transformStructure : PythonOutput -> Exposition
transformStructure python =
    let
        tls =
            combineValues python.toolHtml python.toolText

        -- idea: maybe exposition should use the dict of pages, instead of transforming into a list?
        pages =
            tls |> Dict.toList |> List.map (\( id, ts ) -> GraphicalPage (PageData { pageId = id, tools = ts }))
    in
    Exposition pages


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
    data.content


getText : Exposition -> String
getText (Exposition pages) =
    let
        foldPage page acc =
            getTools page |> List.map toolToText |> String.concat |> (\catted -> acc ++ catted)
    in
    pages |> List.foldl foldPage ""


type alias PageId =
    Int


type PageData
    = PageData
        { pageId : PageId
        , tools : List Tool
        }


pageId (PageData pd) =
    pd.pageId


tools (PageData pd) =
    pd.tools


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


type alias TextData =
    { toolproperties : ToolProperties
    , content : String
    , id : ToolId
    }


toolProperties : Decoder ToolProperties
toolProperties =
    let
        construct ( x, y ) ( w, h ) style =
            { dimensions = { x = x, y = y, w = w, h = h }
            , style = ToolStyle style
            }
    in
    D.map3 construct
        (D.field "position" decodePixelTuple)
        (D.field "size" decodePixelTuple)
        (D.field "style" D.string)


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


type alias Url =
    String


type alias VideoData =
    { toolId : ToolId
    , content : Url
    , toolProperties : ToolProperties
    }



-- add more


type Exposition
    = Exposition (List Page)


simpletext : ToolId -> String -> Tool
simpletext id textContent =
    SimpleTextTool
        { id = id
        , content = textContent
        , toolproperties = dummyToolProperties
        }


htmlText : ToolId -> String -> Tool
htmlText id textContent =
    HtmlTextTool
        { id = id
        , content = textContent
        , toolproperties = dummyToolProperties
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
            D.map2
                construct
                (D.field "id" D.string |> D.map ToolId)
                (D.field "content" D.string)

        pages =
            D.list textTool
    in
    D.keyValuePairs pages
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
