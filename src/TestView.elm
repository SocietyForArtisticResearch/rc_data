module TestView exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Http
import Json.Decode as JD
import ParsedExposition



-- MAIN


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { expositions : List ParsedExposition.Exposition }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { expositions = [] }
    , Http.get
        { url = "vis_data.json"
        , expect = Http.expectJson GotExpositions ParsedExposition.decodeList
        }
    )



-- UPDATE


type Msg
    = GotExpositions (Result Http.Error (List ParsedExposition.Exposition))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotExpositions res ->
            case res of
                Ok exps ->
                    ( { model | expositions = exps }
                    , Cmd.none
                    )

                Err e ->
                    let
                        _ =
                            Debug.log "error: " errorToString e
                    in
                    ( model
                    , Cmd.none
                    )


errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadUrl url ->
            "The URL " ++ url ++ " was invalid"

        Http.Timeout ->
            "Unable to reach the server, try again"

        Http.NetworkError ->
            "Unable to reach the server, check your network connection"

        Http.BadStatus 500 ->
            "The server had a problem, try again later"

        Http.BadStatus 400 ->
            "Verify your information and try again"

        Http.BadStatus _ ->
            "Unknown error"

        Http.BadBody errorMessage ->
            errorMessage



-- VIEW


view : Model -> Html Msg
view model =
    model.expositions
        |> ParsedExposition.pretty



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
