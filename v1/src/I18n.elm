module I18n exposing (Language(..), choose, code, decoder, defaultLanguage, metadata)

import Json.Decode as Decode exposing (Decoder)


type Language
    = English
    | Russian


defaultLanguage : Language
defaultLanguage =
    English


code : Language -> String
code language =
    case language of
        English ->
            "en"

        Russian ->
            "ru"


decoder : Decoder Language
decoder =
    Decode.string
        |> Decode.andThen
            (\value ->
                case value of
                    "en" ->
                        Decode.succeed English

                    "ru" ->
                        Decode.succeed Russian

                    _ ->
                        Decode.fail "Unsupported language"
            )


choose : Language -> { en : String, ru : String } -> String
choose language translations =
    case language of
        English ->
            translations.en

        Russian ->
            translations.ru


metadata : Language -> { code : String, title : String, description : String }
metadata language =
    { code = code language
    , title = choose language { en = "Tishe — a place for yourself", ru = "Тише — место для себя" }
    , description = choose language { en = "Tishe — a personal space to notice tension, explore small practices and reflect with care.", ru = "Тише — личное пространство для наблюдения за напряжением, небольших практик и бережной рефлексии." }
    }
