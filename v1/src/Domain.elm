module Domain exposing (Entry, Feeling(..), Level, Practice(..), PracticeGroup(..), Timer(..), allFeelings, allPracticeGroups, allPractices, decodeEntries, encodeEntries, fromInt, pauseTimer, practiceGroup, tickTimer, timerElapsed, timerMillis, toInt)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Level
    = Level Int


fromInt : Int -> Level
fromInt value =
    Level (clamp 0 10 value)


toInt : Level -> Int
toInt (Level value) =
    value


type Feeling
    = Anxiety
    | Anger
    | Fatigue
    | Sadness
    | Confusion
    | Calm


allFeelings : List Feeling
allFeelings =
    [ Anxiety, Anger, Fatigue, Sadness, Confusion, Calm ]


feelingKey : Feeling -> String
feelingKey feeling =
    case feeling of
        Anxiety ->
            "anxiety"

        Anger ->
            "anger"

        Fatigue ->
            "fatigue"

        Sadness ->
            "sadness"

        Confusion ->
            "confusion"

        Calm ->
            "calm"


feelingDecoder : Decoder Feeling
feelingDecoder =
    Decode.string
        |> Decode.andThen
            (\key ->
                case key of
                    "anxiety" ->
                        Decode.succeed Anxiety

                    "anger" ->
                        Decode.succeed Anger

                    "fatigue" ->
                        Decode.succeed Fatigue

                    "sadness" ->
                        Decode.succeed Sadness

                    "confusion" ->
                        Decode.succeed Confusion

                    "calm" ->
                        Decode.succeed Calm

                    _ ->
                        Decode.fail "Неизвестное чувство"
            )


type alias Entry =
    { at : Int
    , level : Level
    , feelings : List Feeling
    , note : String
    }


encodeEntries : List Entry -> Encode.Value
encodeEntries entries =
    Encode.list
        (\entry ->
            Encode.object
                [ ( "at", Encode.int entry.at )
                , ( "level", Encode.int (toInt entry.level) )
                , ( "feelings", Encode.list (feelingKey >> Encode.string) entry.feelings )
                , ( "note", Encode.string entry.note )
                ]
        )
        entries


levelDecoder : Decoder Level
levelDecoder =
    Decode.int
        |> Decode.andThen
            (\value ->
                if value >= 0 && value <= 10 then
                    Decode.succeed (Level value)

                else
                    Decode.fail "Уровень должен быть от 0 до 10"
            )


decodeEntries : Decoder (List Entry)
decodeEntries =
    Decode.list
        (Decode.map4 Entry
            (Decode.field "at" Decode.int)
            (Decode.field "level" levelDecoder)
            (Decode.field "feelings" (Decode.list feelingDecoder))
            (Decode.field "note" Decode.string)
        )


type Practice
    = Presence
    | Control
    | Conflict
    | ToeWalk
    | CrownReach
    | SensoryWalk
    | BodyContact
    | FingerTapping
    | SelfMassage
    | HeadMassage
    | Breathing
    | WarmPalms


type PracticeGroup
    = Attention
    | Body


allPracticeGroups : List PracticeGroup
allPracticeGroups =
    [ Attention, Body ]


practiceGroup : Practice -> PracticeGroup
practiceGroup practice =
    case practice of
        Presence ->
            Attention

        Control ->
            Attention

        Conflict ->
            Attention

        ToeWalk ->
            Body

        CrownReach ->
            Body

        SensoryWalk ->
            Body

        BodyContact ->
            Body

        FingerTapping ->
            Body

        SelfMassage ->
            Body

        HeadMassage ->
            Body

        Breathing ->
            Body

        WarmPalms ->
            Body


allPractices : List Practice
allPractices =
    [ Presence, Control, Conflict, ToeWalk, CrownReach, SensoryWalk, BodyContact, FingerTapping, SelfMassage, HeadMassage, Breathing, WarmPalms ]


type Timer
    = Ready
    | Starting
    | Running { startedAt : Int, accumulated : Int, now : Int }
    | Paused Int
    | Finished


timerElapsed : Timer -> Int
timerElapsed timer =
    timerMillis timer // 1000


timerMillis : Timer -> Int
timerMillis timer =
    case timer of
        Ready ->
            0

        Starting ->
            0

        Running clock ->
            clamp 0 60000 (clock.accumulated + max 0 (clock.now - clock.startedAt))

        Paused elapsed ->
            elapsed

        Finished ->
            60000


pauseTimer : Int -> Timer -> Timer
pauseTimer now timer =
    case tickTimer now timer of
        Running clock ->
            Paused (timerMillis (Running clock))

        other ->
            other


tickTimer : Int -> Timer -> Timer
tickTimer now timer =
    case timer of
        Running clock ->
            let
                next =
                    Running { clock | now = now }
            in
            if timerElapsed next >= 60 then
                Finished

            else
                next

        Ready ->
            Ready

        Starting ->
            Starting

        Paused elapsed ->
            Paused elapsed

        Finished ->
            Finished
