module DomainTest exposing (suite)

import Content
import Domain exposing (Feeling(..), Practice(..), Timer(..))
import Expect
import Fuzz
import I18n exposing (Language(..))
import Json.Decode as Decode
import Test exposing (Test, describe, fuzz, test)


suite : Test
suite =
    describe "Tension domain"
        [ describe "Level invariant"
            [ fuzz Fuzz.int "all constructed levels are in 0–10" <|
                \raw ->
                    Domain.fromInt raw |> Domain.toInt |> (\level -> Expect.equal True (level >= 0 && level <= 10))
            , test "lower bound" <| \_ -> Domain.fromInt -1 |> Domain.toInt |> Expect.equal 0
            , test "upper bound" <| \_ -> Domain.fromInt 11 |> Domain.toInt |> Expect.equal 10
            , fuzz (Fuzz.intRange 0 10) "valid levels are preserved" <| \level -> Domain.fromInt level |> Domain.toInt |> Expect.equal level
            ]
        , describe "Journal boundary"
            [ test "entries including every feeling and multiline Cyrillic round-trip" <|
                \_ ->
                    let
                        entries =
                            [ { at = 1794070000000, level = Domain.fromInt 8, feelings = Domain.allFeelings, note = "Хочется отдохнуть.\nИ не подвести близких." }
                            , { at = 1794060000000, level = Domain.fromInt 0, feelings = [], note = "" }
                            ]
                    in
                    Decode.decodeValue Domain.decodeEntries (Domain.encodeEntries entries) |> Expect.equal (Ok entries)
            , fuzz (Fuzz.intRange 0 10) "levels survive JSON" <|
                \level ->
                    let
                        entry =
                            { at = 0, level = Domain.fromInt level, feelings = [ Calm ], note = "" }
                    in
                    Decode.decodeValue Domain.decodeEntries (Domain.encodeEntries [ entry ]) |> Expect.equal (Ok [ entry ])
            , test "empty journal round-trips" <|
                \_ -> Decode.decodeValue Domain.decodeEntries (Domain.encodeEntries []) |> Expect.equal (Ok [])
            , test "unknown feelings do not silently erase records" <|
                \_ -> Decode.decodeString Domain.decodeEntries "[{\"at\":0,\"level\":5,\"feelings\":[\"unknown\"],\"note\":\"\"}]" |> Expect.err
            , test "out-of-range persisted levels are rejected" <|
                \_ -> Decode.decodeString Domain.decodeEntries "[{\"at\":0,\"level\":11,\"feelings\":[],\"note\":\"\"}]" |> Expect.err
            , test "missing fields are rejected" <|
                \_ -> Decode.decodeString Domain.decodeEntries "[{\"level\":5}]" |> Expect.err
            ]
        , describe "Practice catalog"
            [ test "all nine body practices are available in order" <|
                \_ ->
                    Domain.allPractices
                        |> List.filter (Domain.practiceGroup >> (==) Domain.Body)
                        |> Expect.equal [ ToeWalk, CrownReach, SensoryWalk, BodyContact, FingerTapping, SelfMassage, HeadMassage, Breathing, WarmPalms ]
            , test "attention practices remain available in order" <|
                \_ ->
                    Domain.allPractices
                        |> List.filter (Domain.practiceGroup >> (==) Domain.Attention)
                        |> Expect.equal [ Presence, Control, Conflict ]
            , test "each selectable group has practices" <|
                \_ ->
                    Domain.allPracticeGroups
                        |> List.map (\group -> List.any (Domain.practiceGroup >> (==) group) Domain.allPractices)
                        |> List.all identity
                        |> Expect.equal True
            , test "each practice has a label, description and specific precaution" <|
                \_ ->
                    Domain.allPractices
                        |> List.all
                            (\practice ->
                                [ Content.practiceLabel Russian practice, Content.practiceDescription Russian practice, Content.practicePrecaution Russian practice ]
                                    |> List.all (String.trim >> String.isEmpty >> not)
                            )
                        |> Expect.equal True
            ]
        , describe "Practice state machine"
            [ test "ready has zero elapsed" <| \_ -> Domain.timerElapsed Ready |> Expect.equal 0
            , test "clock ticks do not start a ready practice" <| \_ -> Domain.tickTimer 90000 Ready |> Expect.equal Ready
            , test "running time derives from the clock, not number of ticks" <|
                \_ -> Running { startedAt = 1000, accumulated = 0, now = 1000 } |> Domain.tickTimer 22000 |> Domain.timerElapsed |> Expect.equal 21
            , test "background tab delay completes practice" <|
                \_ -> Running { startedAt = 1000, accumulated = 0, now = 1000 } |> Domain.tickTimer 100000 |> Expect.equal Finished
            , test "exact deadline completes practice" <|
                \_ -> Running { startedAt = 1000, accumulated = 0, now = 1000 } |> Domain.tickTimer 61000 |> Expect.equal Finished
            , test "paused time never advances" <| \_ -> Domain.tickTimer 100000 (Paused 17000) |> Expect.equal (Paused 17000)
            , test "resume includes time accumulated before pause" <|
                \_ -> Running { startedAt = 50000, accumulated = 17000, now = 50000 } |> Domain.tickTimer 63000 |> Domain.timerElapsed |> Expect.equal 30
            , test "clock going backwards never makes elapsed negative" <|
                \_ -> Running { startedAt = 50000, accumulated = 0, now = 40000 } |> Domain.timerElapsed |> Expect.equal 0
            , test "pause preserves fractional seconds using the click timestamp" <|
                \_ -> Running { startedAt = 1000, accumulated = 0, now = 1500 } |> Domain.pauseTimer 1800 |> Expect.equal (Paused 800)
            , test "repeated subsecond intervals accumulate" <|
                \_ -> Running { startedAt = 3000, accumulated = 800, now = 3000 } |> Domain.pauseTimer 3800 |> Domain.timerMillis |> Expect.equal 1600
            , test "pause at deadline completes the practice" <|
                \_ -> Running { startedAt = 1000, accumulated = 0, now = 60000 } |> Domain.pauseTimer 61000 |> Expect.equal Finished
            , test "finished state is stable" <| \_ -> Domain.tickTimer 200000 Finished |> Expect.equal Finished
            , test "finished means sixty seconds" <| \_ -> Domain.timerElapsed Finished |> Expect.equal 60
            , test "every practice has exactly three nonempty steps" <|
                \_ ->
                    Domain.allPractices
                        |> List.map (Content.practiceSteps Russian >> (\steps -> List.length steps == 3 && List.all (String.isEmpty >> not) steps))
                        |> List.all identity
                        |> Expect.equal True
            ]
        ]
