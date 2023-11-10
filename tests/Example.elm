module Example exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Json.Decode
import ParsedExposition
import Test exposing (..)
import TestData


testJson =
    """

"""


suite : Test
suite =
    let
        result =
            Json.Decode.decodeString ParsedExposition.parsePythonExposition TestData.testJson

        test () =
            Expect.ok result
    in
    describe "test json parser"
        [ Test.test "the parser does not throw an error" test
        ]
