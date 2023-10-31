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
    = SimpleText ToolId String
    | HtmlText String



-- add more


type Exposition
    = Exposition (List Page)


textTools : D.Decoder (Dict PageID (List Tool))
textTools =
    let
        page =
            D.field "id" D.string |> D.map (\i -> SimpleText (ToolId i) "")

        pages =
            D.list page
    in
    D.keyValuePairs pages
        |> D.andThen
            (\lst ->
                lst
                    |> List.map (Tuple.mapFirst (String.toInt |> Maybe.withDefault 0))
                    |> Dict.fromList
            )


page : D.Decoder Page
page =
    D.field "tool-text"
