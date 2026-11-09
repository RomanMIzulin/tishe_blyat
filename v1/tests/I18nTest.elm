module I18nTest exposing (suite)

import Content
import Domain exposing (Practice(..))
import Expect
import I18n exposing (Language(..))
import Json.Decode as Decode
import Test exposing (Test, describe, test)
import Theory


suite : Test
suite =
    describe "Localization"
        [ test "English is the default" <|
            \_ -> Expect.equal English I18n.defaultLanguage
        , test "supported language codes round-trip" <|
            \_ ->
                [ English, Russian ]
                    |> List.map (\language -> Decode.decodeString I18n.decoder ("\"" ++ I18n.code language ++ "\""))
                    |> Expect.equal [ Ok English, Ok Russian ]
        , test "unknown codes and non-string preferences are rejected" <|
            \_ ->
                [ "\"de\"", "\"EN\"", "\"\"", "null", "42", "{}" ]
                    |> List.map (Decode.decodeString I18n.decoder >> Result.toMaybe)
                    |> Expect.equal (List.repeat 6 Nothing)
        , test "translation selection is explicit for both languages" <|
            \_ ->
                [ English, Russian ]
                    |> List.map (\language -> I18n.choose language { en = "English text", ru = "Русский текст" })
                    |> Expect.equal [ "English text", "Русский текст" ]
        , test "document metadata follows the selected language" <|
            \_ ->
                [ English, Russian ]
                    |> List.map
                        (\language ->
                            let
                                locale =
                                    I18n.metadata language
                            in
                            ( locale.code, locale.title )
                        )
                    |> Expect.equal [ ( "en", "Tishe — a place for yourself" ), ( "ru", "Тише — место для себя" ) ]
        , test "level thresholds have distinct labels in both languages" <|
            \_ ->
                [ English, Russian ]
                    |> List.map (\language -> List.map (Domain.fromInt >> Content.levelLabel language) [ 0, 3, 4, 6, 7, 10 ])
                    |> Expect.equal
                        [ [ "There is a little space", "There is a little space", "Tension is noticeable", "Tension is noticeable", "High tension", "High tension" ]
                        , [ "Есть немного пространства", "Есть немного пространства", "Напряжение ощутимо", "Напряжение ощутимо", "Высокое напряжение", "Высокое напряжение" ]
                        ]
        , test "every practice has localized copy and three nonempty steps" <|
            \_ ->
                [ English, Russian ]
                    |> List.all
                        (\language ->
                            List.all
                                (\practice ->
                                    let
                                        steps =
                                            Content.practiceSteps language practice

                                        copy =
                                            [ Content.practiceLabel language practice, Content.practiceDescription language practice, Content.practicePrecaution language practice ] ++ steps
                                    in
                                    List.length steps == 3 && List.all (String.trim >> String.isEmpty >> not) copy
                                )
                                Domain.allPractices
                        )
                    |> Expect.equal True
        , test "English practice copy contains no untranslated Cyrillic" <|
            \_ ->
                Domain.allPractices
                    |> List.concatMap (\practice -> [ Content.practiceLabel English practice, Content.practiceDescription English practice, Content.practicePrecaution English practice ] ++ Content.practiceSteps English practice)
                    |> List.all (String.toList >> List.all (\char -> (char < 'А' || char > 'я') && char /= 'Ё' && char /= 'ё'))
                    |> Expect.equal True
        , test "English precautions retain eye, neck and breathing limits" <|
            \_ ->
                Expect.all
                    [ \_ -> Content.practicePrecaution English WarmPalms |> String.contains "No pressure on your eyes" |> Expect.equal True
                    , \_ -> Content.practicePrecaution English HeadMassage |> String.contains "Do not press on your eyeballs or eyelids" |> Expect.equal True
                    , \_ -> Content.practicePrecaution English CrownReach |> String.contains "let it hang off a bed" |> Expect.equal True
                    , \_ -> Content.practicePrecaution English SelfMassage |> String.contains "front and sides of your neck" |> Expect.equal True
                    , \_ -> Content.practicePrecaution English Breathing |> String.contains "return to your usual breathing" |> Expect.equal True
                    ]
                    ()
        , test "feelings and groups have different labels in each language" <|
            \_ ->
                Expect.equal True
                    (List.all (\feeling -> Content.feelingLabel English feeling /= Content.feelingLabel Russian feeling) Domain.allFeelings
                        && List.all (\group -> Content.practiceGroupLabel English group /= Content.practiceGroupLabel Russian group) Domain.allPracticeGroups
                    )
        , test "every theoretical lens has translated labels, explanations and sources" <|
            \_ ->
                Theory.all
                    |> List.all
                        (\lens ->
                            List.all
                                (\copy -> not (String.isEmpty (copy English lens)) && copy English lens /= copy Russian lens)
                                [ Theory.label, Theory.title, Theory.description, Theory.source ]
                        )
                    |> Expect.equal True
        ]
