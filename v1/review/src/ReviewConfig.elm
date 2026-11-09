module ReviewConfig exposing (config)

import Architecture.DomainBoundary
import Architecture.KeepLevelOpaque
import Architecture.PortsOnlyInMain
import NoDebug.Log
import NoDebug.TodoOrToString
import NoExposingEverything
import Review.Rule exposing (Rule)


config : List Rule
config =
    [ NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
    , NoExposingEverything.rule
    , Architecture.DomainBoundary.rule
    , Architecture.PortsOnlyInMain.rule
    , Architecture.KeepLevelOpaque.rule
    ]
