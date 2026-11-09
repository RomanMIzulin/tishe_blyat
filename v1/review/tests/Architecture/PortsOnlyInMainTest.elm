module Architecture.PortsOnlyInMainTest exposing (suite)

import Architecture.PortsOnlyInMain exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Architecture.PortsOnlyInMain"
        [ test "allows ports in Main" <|
            \() ->
                "port module Main exposing (send)\nport send : String -> Cmd msg"
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "allows an ordinary helper module" <|
            \() ->
                "module Helper exposing (value)\nvalue = 1"
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "rejects a port module and its port declaration outside Main" <|
            \() ->
                "port module Helper exposing (send)\nport send : String -> Cmd msg"
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ portError "port module Helper exposing (send)"
                        , portError "port send : String -> Cmd msg"
                        ]
        , test "does not mistake Main.Child for Main" <|
            \() ->
                "port module Main.Child exposing (send)\nport send : String -> Cmd msg"
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ portError "port module Main.Child exposing (send)"
                        , portError "port send : String -> Cmd msg"
                        ]
        , test "rejects a port declaration even without a port header" <|
            \() ->
                "module Helper exposing (send)\nport send : String -> Cmd msg"
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors [ portError "port send : String -> Cmd msg" ]
        ]


portError : String -> Review.Test.ExpectedError
portError under =
    Review.Test.error
        { message = "Ports belong only in Main"
        , details = [ "Keep the browser IO contract in Main and implement it in bridge.js. Do not create another port module or declare ports in a domain or UI helper." ]
        , under = under
        }
