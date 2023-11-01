module ParsedExposition exposing (..)

import Dict exposing (Dict)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as E
import Research exposing (ExpositionID)


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
    }


expositionId : Decoder ExpositionID
expositionId =
    D.int


parsePython : Decoder PythonOutput
parsePython =
    D.succeed PythonOutput
        |> andMap (D.field "id" expositionId)
        |> andMap (D.field "type" editorType)
        |> andMap (D.field "pages" (D.list D.string))
        |> andMap (D.field "tool-text" (toolText HtmlText))
        |> andMap (D.field "tool-simpletext" (toolText SimpleText))


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
    = ToolStyle



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


dummyToolProperties : ToolProperties
dummyToolProperties =
    { dimensions = { x = 0, y = 0, w = 0, h = 0 }
    , style = ToolStyle
    }


type ToolId
    = ToolId String


type Tool
    = SimpleTextTool TextData
    | HtmlTextTool TextData



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
