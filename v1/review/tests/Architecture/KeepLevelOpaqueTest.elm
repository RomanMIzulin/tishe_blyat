module Architecture.KeepLevelOpaqueTest exposing (suite)

import Architecture.KeepLevelOpaque exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Architecture.KeepLevelOpaque"
        [ test "allows an opaque Level and public constructors of other types" <|
            \() ->
                "module Domain exposing (Level, Feeling(..))\ntype Level = Level Int\ntype Feeling = Calm"
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "rejects public Level constructors" <|
            \() ->
                "module Domain exposing (Level(..))\ntype Level = Level Int"
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors [ constructorError "Level(..)" ]
        , test "rejects exposing everything from Domain" <|
            \() ->
                "module Domain exposing (..)\ntype Level = Level Int"
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors [ constructorError ".." ]
        , test "rejects a transparent Level alias" <|
            \() ->
                "module Domain exposing (Level)\ntype alias Level = Int"
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Level must remain a custom type"
                            , details = [ "A type alias is transparent even when its name is exposed without constructors. Keep Level as an opaque custom type; its range remains a behavioral invariant checked by domain tests." ]
                            , under = "type alias Level = Int"
                            }
                        ]
        , test "allows other domain aliases" <|
            \() ->
                "module Domain exposing (Entry, Level)\ntype Level = Level Int\ntype alias Entry = { level : Level }"
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "does not restrict unrelated modules" <|
            \() ->
                "module DomainTest exposing (..)\ntype alias Level = Int"
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        ]


constructorError : String -> Review.Test.ExpectedError
constructorError under =
    Review.Test.error
        { message = "Keep the Level constructor private"
        , details = [ "Expose Domain.Level by name, not through exposing (..) or Level(..). Construction must stay behind the domain functions and decoder." ]
        , under = under
        }
