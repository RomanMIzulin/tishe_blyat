module ReviewConfigTest exposing (suite)

import Expect
import Review.Rule
import ReviewConfig
import Test exposing (Test, test)


suite : Test
suite =
    test "the npm review configuration enables all six guards" <|
        \() ->
            ReviewConfig.config
                |> List.map Review.Rule.ruleName
                |> Expect.equal
                    [ "NoDebug.Log"
                    , "NoDebug.TodoOrToString"
                    , "NoExposingEverything"
                    , "Architecture.DomainBoundary"
                    , "Architecture.PortsOnlyInMain"
                    , "Architecture.KeepLevelOpaque"
                    ]
