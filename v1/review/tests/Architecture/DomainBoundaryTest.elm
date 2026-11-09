module Architecture.DomainBoundaryTest exposing (suite)

import Architecture.DomainBoundary exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Architecture.DomainBoundary"
        [ describe "Explicit dependency boundary"
            ([ test "allows JSON and approved pure core imports" <|
                \() ->
                    """module Domain exposing (value)
import Array
import Basics
import Bitwise
import Char
import Dict
import List
import Maybe
import Result
import Set
import String
import Tuple
import Json.Decode as Decode
import Json.Encode as Encode
value = 1
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
             , test "does not mistake DomainTest for Domain" <|
                \() ->
                    "module DomainTest exposing (value)\nimport Html\nvalue = 1"
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
             , test "allows effects in Main" <|
                \() ->
                    "module Main exposing (value)\nvalue : Cmd msg\nvalue = Cmd.none"
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
             ]
                ++ List.map rejectsImport
                    [ "Html"
                    , "Html.Attributes"
                    , "Browser"
                    , "Task"
                    , "Http"
                    , "Time"
                    , "Platform.Cmd"
                    , "Platform.Sub"
                    , "DomainHelpers"
                    , "Domain.Helpers"
                    , "Debug"
                    ]
            )
        , describe "Default effects and nested annotations"
            (List.map rejectsEffect
                [ { name = "implicit Cmd value", body = "value = Cmd.none", under = "Cmd.none" }
                , { name = "implicit Sub value", body = "value = Sub.none", under = "Sub.none" }
                , { name = "implicit Platform value", body = "value = Platform.worker", under = "Platform.worker" }
                , { name = "implicit Cmd type", body = "type alias Value msg = Cmd msg", under = "Cmd" }
                , { name = "qualified Sub type", body = "type alias Value msg = Platform.Sub.Sub msg", under = "Platform.Sub.Sub" }
                , { name = "Program type", body = "type alias Value flags model msg = Program flags model msg", under = "Program" }
                , { name = "nested generic argument", body = "type alias Value msg = Maybe (Cmd msg)", under = "Cmd" }
                , { name = "tuple item", body = "type alias Value msg = ( Int, Sub msg )", under = "Sub" }
                , { name = "record field", body = "type alias Value msg = { command : Cmd msg }", under = "Cmd" }
                , { name = "extensible record field", body = "type alias Value fields msg = { fields | subscription : Sub msg }", under = "Sub" }
                , { name = "function argument", body = "type alias Value msg = Cmd msg -> Int", under = "Cmd" }
                , { name = "function result", body = "type alias Value msg = Int -> Sub msg", under = "Sub" }
                , { name = "constructor argument", body = "type Value msg = Waiting (Cmd msg)", under = "Cmd" }
                , { name = "top-level signature", body = "value : Cmd msg -> Int\nvalue _ = 0", under = "Cmd" }
                , { name = "let signature", body = "value =\n    let\n        make : Cmd msg -> Int\n        make _ = 0\n    in\n    make", under = "Cmd" }
                , { name = "nested let signature", body = "value =\n    let\n        outer =\n            let\n                make : Sub msg -> Int\n                make _ = 0\n            in\n            make\n    in\n    outer", under = "Sub" }
                ]
            )
        , test "resolves an aliased effect module" <|
            \() ->
                "module Domain exposing (value)\n\nimport Platform.Cmd as Effects\n\nvalue = Effects.none"
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ importError "Platform.Cmd"
                        , effectError "Effects.none"
                        ]
        , test "resolves an exposed effect value" <|
            \() ->
                "module Domain exposing (value)\n\nimport Platform.Cmd exposing (none)\n\nvalue = none"
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ importError "Platform.Cmd"
                        , effectError "none"
                            |> Review.Test.atExactly { start = { row = 5, column = 9 }, end = { row = 5, column = 13 } }
                        ]
        , test "resolves an aliased effect type" <|
            \() ->
                "module Domain exposing (Value)\n\nimport Platform.Sub as Events\n\ntype alias Value msg = Events.Sub msg"
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ importError "Platform.Sub"
                        , effectError "Events.Sub"
                        ]
        , test "does not flag local pure types named Cmd, Sub and Program" <|
            \() ->
                """module Domain exposing (Value)

type Cmd a = Pure a
type alias Sub = Int
type alias Program = String
type alias Value = ( Cmd Int, Sub, Program )
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "does not mistake a pure module aliased to Cmd for an effect" <|
            \() ->
                "module Domain exposing (value)\nimport Array as Cmd\nvalue = Cmd.empty"
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "ignores mentions of effects in strings and comments" <|
            \() ->
                "module Domain exposing (value)\n-- Cmd.none is not executed here\nvalue = \"Sub.none\""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "does not flag an unrelated local value named none" <|
            \() ->
                "module Domain exposing (none)\nnone = 0"
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        ]


rejectsImport : String -> Test
rejectsImport moduleName =
    test ("rejects importing " ++ moduleName) <|
        \() ->
            ("module Domain exposing (value)\n\nimport " ++ moduleName ++ "\n\nvalue = 1")
                |> Review.Test.run rule
                |> Review.Test.expectErrors [ importError moduleName ]


type alias EffectCase =
    { name : String
    , body : String
    , under : String
    }


rejectsEffect : EffectCase -> Test
rejectsEffect example =
    test ("rejects " ++ example.name) <|
        \() ->
            ("module Domain exposing (Value, value)\n\n" ++ example.body)
                |> Review.Test.run rule
                |> Review.Test.expectErrors [ effectError example.under ]


importError : String -> Review.Test.ExpectedError
importError under =
    Review.Test.error
        { message = "Domain imports a module outside its pure boundary"
        , details = [ "Domain may import only the approved pure core modules and Json.Decode/Json.Encode. Keep UI and effects outside Domain; review this allowlist explicitly before adding a pure helper module." ]
        , under = under
        }


effectError : String -> Review.Test.ExpectedError
effectError under =
    Review.Test.error
        { message = "Domain must not describe runtime effects"
        , details = [ "Move Program, Cmd and Sub types and values to Main. This check resolves actual origins, including default imports, aliases and exposed names; a locally defined pure type with the same name is not an effect." ]
        , under = under
        }
