module ParsedExposition exposing (..)

import AppUrl
import Color exposing (Color)
import Dict exposing (Dict)
import Expo exposing (ImageType, PageID, ToolContent)
import Html exposing (Html, a, text)
import Html.Attributes
import Json.Decode as D exposing (Decoder)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as E
import Research exposing (ExpositionID)
import Time exposing (Posix)


type alias Dimensions =
    { x : Int, y : Int, w : Int, h : Int }


type EditorType
    = Graph
    | Block
    | TextBased


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
        [ page |> .id |> printId
        , Html.ul [] (page |> getTools |> List.map prettyTool)
        ]


toolWithColor : String -> Color -> Html msg
toolWithColor name color =
    Html.span [ Html.Attributes.style "color" (Color.toCssString color) ] [ text name ]


prettyTool : Tool -> Html msg
prettyTool (Tool tl) =
    case tl.content of
        SimpleText _ ->
            toolWithColor " txt " Color.red

        HtmlText _ ->
            toolWithColor " html " Color.blue

        Image _ ->
            toolWithColor " image tool " Color.brown

        Video _ ->
            toolWithColor " video tool " Color.darkYellow

        Pdf _ ->
            toolWithColor " pdf tool " Color.darkGray


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


type alias ExpositionContent =
    { id : Int
    , url : String
    , pages : List Page
    }


type alias Page =
    { id : PageID
    , type_ : EditorType
    , textTools : List Tool
    , htmlTools : List Tool
    , imageTools : List Tool
    , videoTools : List Tool
    }


expositionId : Decoder ExpositionID
expositionId =
    D.int


pageId : Decoder PageId
pageId =
    D.int


decodePage : Decoder Page
decodePage =
    D.succeed Page
        |> andMap (D.field "id" pageId)
        |> andMap (D.field "type" editorType)
        |> andMap (D.field "tool-text" (D.list (decodeTool HtmlContent)))
        |> andMap (D.field "tool-simpletext" (D.list (decodeTool TextContent)))
        |> andMap (D.field "tool-picture" (D.list (decodeTool ImageContent)))
        |> andMap (D.field "tool-video" (D.list (decodeTool VideoContent)))


parsePythonExposition : Decoder Exposition
parsePythonExposition =
    D.map2 (\ps id -> Exposition { pages = ps, id = id })
        (D.field "pages" (D.list decodePage))
        (D.field "id" expositionId)



-- |> andMap (D.field "tool-text" (toolText HtmlText))
-- |> andMap (D.field "tool-simpletext" (toolText SimpleText))
-- |> andMap (D.field "tool-picture" toolImage)
-- |> andMap (D.field "tool-video" toolVideo)


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


getTools : Page -> List Tool
getTools page =
    page.textTools ++ page.imageTools ++ page.videoTools


toolToText : Tool -> String
toolToText (Tool tool) =
    case tool.content of
        SimpleText text ->
            text

        HtmlText text ->
            text

        Image _ ->
            ""

        Video _ ->
            ""

        Pdf _ ->
            ""



-- TODO: maybe we can do something clever for other tools


getText : Exposition -> String
getText (Exposition data) =
    let
        foldPage page acc =
            getTools page |> List.map toolToText |> String.concat |> (\catted -> acc ++ catted)
    in
    data.pages |> List.foldl foldPage ""


type alias PageId =
    Int


printId : PageId -> Html msg
printId i =
    Html.text ("page id: " ++ String.fromInt i)


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


type ToolContentType
    = ImageContent
    | VideoContent
    | TextContent
    | HtmlContent
    | PdfContent


decodeToolContent : ToolContentType -> Decoder ToolContent
decodeToolContent contentType =
    case contentType of
        ImageContent ->
            D.field "src" D.string |> D.map (\url -> Image { src = url })

        VideoContent ->
            D.map2 (\url preview -> Video { src = url, preview = preview })
                (D.field "src" D.string)
                (D.field "poster" D.string)

        TextContent ->
            D.field "src" D.string |> D.map HtmlText

        HtmlContent ->
            D.field "src" D.string |> D.map SimpleText

        PdfContent ->
            D.field "src" D.string |> D.map (\url -> Pdf { src = url })


decodeTool : ToolContentType -> Decoder Tool
decodeTool contentType =
    let
        content =
            decodeToolContent contentType
    in
    content
        |> D.andThen
            (\c ->
                D.succeed (constructToolWithContent c)
                    |> andMap
                        (D.field "id" D.int |> D.map mkToolId)
                    |> andMap
                        (D.field "tool" D.string)
                    |> andMap
                        (D.field "style" D.string)
                    |> andMap
                        (D.field "dimensions" decodeDimensions)
            )


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



-- decodePixelTuple : Decoder ( Int, Int )
-- decodePixelTuple =
--     D.list D.string
--         |> D.andThen
--             (\lst ->
--                 case lst of
--                     [ x, y ] ->
--                         [ x, y ]
--                             |> List.map (String.replace "px" "" >> String.toInt)
--                             |> List.filterMap identity
--                             |> (\lst2 ->
--                                     case lst2 of
--                                         [ i1, i2 ] ->
--                                             D.succeed ( i1, i2 )
--                                         _ ->
--                                             D.fail "expected two integers with "
--                                )
--                     _ ->
--                         D.fail "expected two px values"
--             )


type ToolId
    = ToolId Int

mkToolId : Int -> ToolId
mkToolId = 
    ToolId

type Tool
    = Tool
        { content : ToolContent
        , id : ToolId
        , dimensions : Dimensions
        , style : ToolStyle
        , rawHtmlContent : String
        }


type ToolContent
    = SimpleText String
    | HtmlText String
    | Image
        { src : String
        }
    | Video
        { src : Url
        , preview : Url
        }
    | Pdf { src : String }


type alias Url =
    String


getSize : Tool -> Dimensions
getSize (Tool tool) =
    tool.dimensions



-- add more


type Exposition
    = Exposition { pages : List Page, id : ExpositionID }


constructToolWithContent : ToolContent -> ToolId -> String -> String -> Dimensions -> Tool
constructToolWithContent content toolId rawHtml style dim =
    Tool
        { content = content
        , id = toolId
        , rawHtmlContent = rawHtml
        , style = ToolStyle style
        , dimensions = dim
        }


type TextToolType
    = SimpleTxt
    | HtmlTxt


debugValue : String -> a -> a
debugValue label x =
    let
        _ =
            Debug.log label x
    in
    x
