module ParsedExposition exposing (..)

import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E
import Research exposing (ExpositionID)


type alias Dimensions =
    { x : Int, y : Int, w : Int, h : Int }


type TextData
    = TextData String



-- needs to have tools and other stuff


type Page
    = GraphicalPage PageData
    | BlockPage PageData
    | TextPage TextData


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


type alias SimpleTextData =
    { toolproperties : ToolProperties
    , text : String
    }


type ToolId
    = ToolId String


type Tool
    = SimpleText SimpleTextData
    | HtmlText String



-- add more


type Exposition
    = Exposition (List Page)


simpletext : ToolId -> String -> Tool
simpletext id textContent =
    SimpleText id textContent


tool_text : D.Decoder (Dict PageID (List Tool))
tool_text =
    let
        textTool =
            D.map2
                simpletext
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


page : D.Decoder Page
page =
    D.field "tool-text"
