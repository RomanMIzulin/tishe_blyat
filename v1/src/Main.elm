port module Main exposing (main)

import Browser
import Content
import Domain exposing (Entry, Feeling, Practice(..), Timer(..))
import Html exposing (Html, a, aside, button, div, footer, h1, h2, h3, header, input, label, main_, nav, p, section, span, strong, text, textarea)
import Html.Attributes exposing (attribute, class, disabled, for, href, id, maxlength, name, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import I18n exposing (Language(..))
import Json.Decode as Decode
import Json.Encode as Encode
import Task
import Theory
import Time


port localeChanged : { code : String, title : String, description : String } -> Cmd msg


port rememberLanguage : String -> Cmd msg


port languageResult : (LanguageWriteResult -> msg) -> Sub msg


port persist : Encode.Value -> Cmd msg


port storageResult : (Bool -> msg) -> Sub msg


port storageConflict : (() -> msg) -> Sub msg


port clearStorage : () -> Cmd msg


port download : Encode.Value -> Cmd msg


type Page
    = Today
    | Journal
    | Practices
    | Why


type Range
    = Week
    | Month
    | AllTime


type SaveState
    = Editing
    | Saving
    | Saved


type Storage
    = Local
    | Unavailable
    | Invalid
    | ConflictDetected
    | DeleteFailed


type Deletion
    = NotDeleting
    | ConfirmingDeletion
    | Deleting


type LanguagePreference
    = PreferenceReady
    | PreferenceSaving
    | PreferenceSaved
    | PreferenceFailed


type alias LanguageWriteResult =
    { code : String
    , success : Bool
    }


type alias Model =
    { language : Language
    , languagePreference : LanguagePreference
    , page : Page
    , level : Domain.Level
    , feelings : List Feeling
    , note : String
    , entries : List Entry
    , saving : SaveState
    , storage : Storage
    , practice : Practice
    , timer : Timer
    , lens : Theory.Lens
    , range : Range
    , now : Time.Posix
    , zone : Time.Zone
    , deletion : Deletion
    }


type Msg
    = LanguageSelected Language
    | LanguagePreferenceResponded LanguageWriteResult
    | Navigated Page
    | LevelChanged String
    | FeelingToggled Feeling
    | NoteChanged String
    | SaveClicked
    | SaveClockReceived Time.Posix
    | ClockReceived Time.Posix
    | ZoneReceived Time.Zone
    | StorageResponded Bool
    | StorageChangedElsewhere
    | PracticeSelected Practice
    | StartClicked
    | StartClockReceived Time.Posix
    | PauseClicked
    | PauseClockReceived Time.Posix
    | ResetClicked
    | Ticked Time.Posix
    | LensSelected Theory.Lens
    | RangeSelected Range
    | ExportClicked
    | DeleteRequested
    | DeleteCancelled
    | DeleteConfirmed


main : Program Decode.Value Model Msg
main =
    Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        language =
            Decode.decodeValue (Decode.field "language" I18n.decoder) flags |> Result.withDefault I18n.defaultLanguage

        raw =
            Decode.decodeValue (Decode.field "saved" (Decode.nullable Domain.decodeEntries)) flags

        unavailable =
            Decode.decodeValue (Decode.field "unavailable" Decode.bool) flags |> Result.withDefault False

        ( entries, storage ) =
            case raw of
                Ok maybeEntries ->
                    ( Maybe.withDefault [] maybeEntries
                    , if unavailable then
                        Unavailable

                      else
                        Local
                    )

                Err _ ->
                    ( [], Invalid )
    in
    ( { language = language
      , languagePreference = PreferenceReady
      , page = Today
      , level = Domain.fromInt 5
      , feelings = []
      , note = ""
      , entries = entries
      , saving = Editing
      , storage = storage
      , practice = Presence
      , timer = Ready
      , lens = Theory.Stoic
      , range = Week
      , now = Time.millisToPosix 0
      , zone = Time.utc
      , deletion = NotDeleting
      }
    , Cmd.batch [ Task.perform ClockReceived Time.now, Task.perform ZoneReceived Time.here, localeChanged (I18n.metadata language) ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LanguageSelected language ->
            ( { model | language = language, languagePreference = PreferenceSaving }
            , Cmd.batch [ localeChanged (I18n.metadata language), rememberLanguage (I18n.code language) ]
            )

        LanguagePreferenceResponded result ->
            if result.code /= I18n.code model.language then
                ( model, Cmd.none )

            else
                ( { model
                    | languagePreference =
                        if result.success then
                            PreferenceSaved

                        else
                            PreferenceFailed
                  }
                , Cmd.none
                )

        Navigated page ->
            ( { model
                | page = page
                , deletion =
                    if model.deletion == Deleting then
                        Deleting

                    else
                        NotDeleting
              }
            , Cmd.none
            )

        LevelChanged raw ->
            ( { model | level = Domain.fromInt (String.toInt raw |> Maybe.withDefault 5), saving = Editing }, Cmd.none )

        FeelingToggled feeling ->
            ( { model
                | feelings =
                    if List.member feeling model.feelings then
                        List.filter ((/=) feeling) model.feelings

                    else
                        model.feelings ++ [ feeling ]
                , saving = Editing
              }
            , Cmd.none
            )

        NoteChanged note ->
            ( { model | note = String.left 2000 note, saving = Editing }, Cmd.none )

        SaveClicked ->
            case ( model.saving, model.storage, model.deletion ) of
                ( Saving, _, _ ) ->
                    ( model, Cmd.none )

                ( Saved, _, _ ) ->
                    ( model, Cmd.none )

                ( Editing, Invalid, _ ) ->
                    ( model, Cmd.none )

                ( Editing, ConflictDetected, _ ) ->
                    ( model, Cmd.none )

                ( Editing, _, Deleting ) ->
                    ( model, Cmd.none )

                ( Editing, _, _ ) ->
                    ( { model | saving = Saving }, Task.perform SaveClockReceived Time.now )

        SaveClockReceived now ->
            let
                entry =
                    { at = Time.posixToMillis now, level = model.level, feelings = model.feelings, note = String.trim model.note }

                entries =
                    entry :: model.entries
            in
            ( { model | entries = entries, now = now }, persist (Domain.encodeEntries entries) )

        ClockReceived now ->
            ( { model | now = now }, Cmd.none )

        ZoneReceived zone ->
            ( { model | zone = zone }, Cmd.none )

        StorageResponded success ->
            case ( model.deletion, success ) of
                ( Deleting, True ) ->
                    ( { model | entries = [], deletion = NotDeleting, storage = Local, saving = Editing, note = "", feelings = [] }, Cmd.none )

                ( Deleting, False ) ->
                    ( { model | deletion = ConfirmingDeletion, storage = DeleteFailed }, Cmd.none )

                ( _, True ) ->
                    ( { model | storage = Local, saving = Saved }, Cmd.none )

                ( _, False ) ->
                    ( { model | storage = Unavailable, saving = Saved }, Cmd.none )

        StorageChangedElsewhere ->
            ( { model | storage = ConflictDetected, saving = Saved }, Cmd.none )

        PracticeSelected practice ->
            ( { model | practice = practice, timer = Ready, page = Practices }, Cmd.none )

        StartClicked ->
            case model.timer of
                Ready ->
                    ( { model | timer = Starting }, Task.perform StartClockReceived Time.now )

                Paused _ ->
                    ( model, Task.perform StartClockReceived Time.now )

                Finished ->
                    ( { model | timer = Starting }, Task.perform StartClockReceived Time.now )

                Starting ->
                    ( model, Cmd.none )

                Running _ ->
                    ( model, Cmd.none )

        StartClockReceived now ->
            case model.timer of
                Starting ->
                    ( { model | timer = Running { startedAt = Time.posixToMillis now, accumulated = 0, now = Time.posixToMillis now } }, Cmd.none )

                Paused elapsed ->
                    ( { model | timer = Running { startedAt = Time.posixToMillis now, accumulated = elapsed, now = Time.posixToMillis now } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PauseClicked ->
            case model.timer of
                Running _ ->
                    ( model, Task.perform PauseClockReceived Time.now )

                _ ->
                    ( model, Cmd.none )

        PauseClockReceived now ->
            ( { model | timer = Domain.pauseTimer (Time.posixToMillis now) model.timer }, Cmd.none )

        ResetClicked ->
            ( { model | timer = Ready }, Cmd.none )

        Ticked now ->
            ( { model | timer = Domain.tickTimer (Time.posixToMillis now) model.timer, now = now }, Cmd.none )

        LensSelected lens ->
            ( { model | lens = lens }, Cmd.none )

        RangeSelected range ->
            ( { model | range = range }, Task.perform ClockReceived Time.now )

        ExportClicked ->
            ( model, download (Domain.encodeEntries model.entries) )

        DeleteRequested ->
            ( { model | deletion = ConfirmingDeletion }, Cmd.none )

        DeleteCancelled ->
            ( { model | deletion = NotDeleting }, Cmd.none )

        DeleteConfirmed ->
            case model.deletion of
                ConfirmingDeletion ->
                    ( { model | deletion = Deleting }, clearStorage () )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ languageResult LanguagePreferenceResponded
        , storageResult StorageResponded
        , storageConflict (always StorageChangedElsewhere)
        , case model.timer of
            Running _ ->
                Time.every 250 Ticked

            _ ->
                Sub.none
        ]


view : Model -> Html Msg
view model =
    div [ class "app-shell" ]
        [ viewSidebar model.language model.page
        , div [ class "workspace" ]
            [ header [ class "topbar" ]
                [ span [ class "breadcrumb" ] [ text (I18n.choose model.language { en = "Personal space / ", ru = "Личное пространство / " } ++ pageLabel model.language model.page) ]
                , viewLanguageSwitch model.language model.languagePreference
                , div [ class "local-status" ] [ span [ class "status-dot" ] [], text (I18n.choose model.language { en = "Only on your device", ru = "Только на твоём устройстве" }) ]
                ]
            , main_ [ id "main-content" ]
                [ viewStorage model.language model.storage
                , case model.page of
                    Today ->
                        viewToday model

                    Journal ->
                        viewJournal model

                    Practices ->
                        viewPractices model

                    Why ->
                        div [ class "page-inner" ]
                            [ viewPageTitle (I18n.choose model.language { en = "UNDERSTAND, NOT FIX", ru = "ПОНЯТЬ, А НЕ ПОЧИНИТЬ" }) (I18n.choose model.language { en = "Why Tishe?", ru = "Почему «Тише»?" }) (I18n.choose model.language { en = "Not every feeling needs to go away. Find a little more freedom in how you respond.", ru = "Не избавляться от каждого чувства. Найти чуть больше свободы в том, как с ним быть." })
                            , section [ class "card theory-full" ] [ Theory.view model.language model.lens LensSelected ]
                            ]
                , footer [ class "footer" ]
                    [ span [] [ text (I18n.choose model.language { en = "Less pressure on yourself. More attention.", ru = "Меньше требований к себе. Больше внимания." }) ]
                    , span [] [ text (I18n.choose model.language { en = "A space for self-observation.", ru = "Пространство для самонаблюдения." }), text " ", button [ class "inline-link", onClick (Navigated Why) ] [ text (I18n.choose model.language { en = "About the ideas and approach ↗", ru = "Об идеях и подходе ↗" }) ] ]
                    ]
                ]
            ]
        ]


viewLanguageSwitch : Language -> LanguagePreference -> Html Msg
viewLanguageSwitch language preference =
    div [ class "language-control" ]
        [ div [ class "language-switch", attribute "role" "group", attribute "aria-label" (I18n.choose language { en = "Language", ru = "Язык" }) ]
            (List.map
                (\selected ->
                    button
                        [ class "language-option"
                        , onClick (LanguageSelected selected)
                        , attribute "lang" (I18n.code selected)
                        , attribute "aria-pressed"
                            (if language == selected then
                                "true"

                             else
                                "false"
                            )
                        ]
                        [ text
                            (case selected of
                                English ->
                                    "English"

                                Russian ->
                                    "Русский"
                            )
                        ]
                )
                [ English, Russian ]
            )
        , if preference == PreferenceFailed then
            p [ class "language-hint", attribute "role" "status" ]
                [ text (I18n.choose language { en = "Could not remember the language. This choice applies until reload.", ru = "Не удалось запомнить язык. Выбор действует до перезагрузки." }) ]

          else
            text ""
        ]


pageLabel : Language -> Page -> String
pageLabel language page =
    case page of
        Today ->
            I18n.choose language { en = "Now", ru = "Сейчас" }

        Journal ->
            I18n.choose language { en = "Journal", ru = "Дневник" }

        Practices ->
            I18n.choose language { en = "Practices", ru = "Практики" }

        Why ->
            I18n.choose language { en = "Why this is here", ru = "Почему это здесь" }


viewSidebar : Language -> Page -> Html Msg
viewSidebar language page =
    aside [ class "sidebar" ]
        [ a [ href "#main-content", class "skip-link" ] [ text (I18n.choose language { en = "Skip to content", ru = "К содержимому" }) ]
        , a [ class "brand", href "#", onClick (Navigated Today), attribute "aria-label" (I18n.choose language { en = "Tishe — home", ru = "Тише — на главную" }) ]
            [ div [ class "brand-mark", attribute "aria-hidden" "true" ] [ span [] [], span [] [], span [] [], span [] [] ]
            , span [] [ text (I18n.choose language { en = "tishe", ru = "тише" }), span [ class "brand-period" ] [ text "." ] ]
            ]
        , p [ class "brand-caption" ] [ text (I18n.choose language { en = "A PLACE FOR YOURSELF", ru = "МЕСТО ДЛЯ СЕБЯ" }) ]
        , nav [ class "nav", attribute "aria-label" (I18n.choose language { en = "Main navigation", ru = "Основная навигация" }) ]
            (List.map
                (\( destination, symbol ) ->
                    button
                        [ class
                            (if page == destination then
                                "nav-item active"

                             else
                                "nav-item"
                            )
                        , onClick (Navigated destination)
                        , attribute "aria-current"
                            (if page == destination then
                                "page"

                             else
                                "false"
                            )
                        ]
                        [ span [ class "nav-icon", attribute "aria-hidden" "true" ] [ text symbol ], text (pageLabel language destination), span [ class "nav-active-dot" ] [] ]
                )
                [ ( Today, "◉" ), ( Journal, "▤" ), ( Practices, "≋" ), ( Why, "⌘" ) ]
            )
        , div [ class "sidebar-bottom" ]
            [ div [ class "sidebar-note" ] [ p [] [ text (I18n.choose language { en = "You are not a project to improve.", ru = "Ты не проект, который нужно улучшить." }) ], span [] [ text (I18n.choose language { en = "You can just be here.", ru = "Можно просто побыть." }) ] ]
            , div [ class "private-label" ] [ span [ attribute "aria-hidden" "true" ] [ text "♧" ], text (I18n.choose language { en = "No account. No judgment.", ru = "Без аккаунта. Без оценок." }) ]
            ]
        ]


viewStorage : Language -> Storage -> Html Msg
viewStorage language storage =
    case storage of
        Local ->
            text ""

        Unavailable ->
            div [ class "storage-warning", attribute "role" "alert" ] [ text (I18n.choose language { en = "Could not save data in this browser. New entries will be lost on reload — download them from the journal. Storage may be blocked or full.", ru = "Не удалось сохранить данные в браузере. Новые записи доступны только до перезагрузки — скачай их в дневнике. Возможна блокировка хранилища или нехватка места." }) ]

        ConflictDetected ->
            div [ class "storage-warning", attribute "role" "alert" ] [ text (I18n.choose language { en = "The journal changed in another tab. This tab did not overwrite its entries. Download your entries from the Journal before reloading: your new moment is only in this tab’s memory.", ru = "Дневник изменён в другой вкладке. Эта вкладка не перезаписала чужие записи. Скачай свои записи в разделе «Дневник» перед обновлением страницы: новый момент пока только в памяти этой вкладки." }) ]

        DeleteFailed ->
            div [ class "storage-warning", attribute "role" "alert" ] [ text (I18n.choose language { en = "Data was not deleted: the browser rejected the operation. Your entries are still on screen; you can download a copy or try deleting again.", ru = "Данные не удалены: браузер отклонил операцию. Записи оставлены на экране; можно скачать копию или повторить удаление." }) ]

        Invalid ->
            div [ class "storage-warning", attribute "role" "alert" ] [ text (I18n.choose language { en = "Could not read the saved data. New entries are disabled to avoid overwriting it. For recovery, copy the value of tishe.entries.v1 from localStorage using browser developer tools, or clear the data from the Journal.", ru = "Сохранённые данные не удалось прочитать. Чтобы не перезаписать их, новые записи отключены. Скопируй значение tishe.entries.v1 из localStorage через инструменты браузера для восстановления или очисти данные через раздел «Дневник»." }) ]


viewPageTitle : String -> String -> String -> Html Msg
viewPageTitle eyebrow title subtitle =
    div [ class "page-title" ]
        [ p [ class "eyebrow" ] [ text eyebrow ]
        , h1 [] [ text title ]
        , p [ class "subtitle" ] [ text subtitle ]
        ]


viewToday : Model -> Html Msg
viewToday model =
    div [ class "page-inner" ]
        [ div [ class "welcome-row" ]
            [ viewPageTitle (I18n.choose model.language { en = "A SMALL PAUSE IN YOUR DAY", ru = "НЕБОЛЬШАЯ ПАУЗА В ТВОЁМ ДНЕ" }) (I18n.choose model.language { en = "How are you right now?", ru = "Как ты сейчас?" }) (I18n.choose model.language { en = "You don’t have to feel okay to give yourself some attention.", ru = "Не обязательно быть в порядке, чтобы уделить себе внимание." })
            , span [ class "date-label" ] [ text (formatDate model.language model.zone model.now) ]
            ]
        , div [ class "dashboard-grid" ]
            [ section [ class "card checkin-card" ] [ viewCheckin model ]
            , section [ class "pause-card" ] [ viewPauseCard model.language ]
            , section [ class "card history-preview" ] [ viewHistoryPreview model ]
            , section [ class "thought-card" ]
                [ p [ class "eyebrow" ] [ text (I18n.choose model.language { en = "A THOUGHT TO SIT WITH", ru = "МЫСЛЬ, С КОТОРОЙ МОЖНО ПОБЫТЬ" }) ]
                , p [ class "thought" ] [ text (I18n.choose model.language { en = "Not everything you feel needs to change right away.", ru = "Не всё, что ты чувствуешь, нужно немедленно менять." }) ]
                , div [ class "thought-bottom" ] [ span [] [ text (I18n.choose model.language { en = "Noticing is a beginning.", ru = "Заметить — уже начало." }) ], button [ class "circle-link", onClick (Navigated Why), attribute "aria-label" (I18n.choose model.language { en = "Read about the ideas behind the app", ru = "Читать об основаниях приложения" }) ] [ text "↗" ] ]
                ]
            ]
        , section [ class "card why-preview" ]
            [ div [ class "why-preview-icon", attribute "aria-hidden" "true" ] [ text "∴" ]
            , div [] [ p [ class "eyebrow" ] [ text (I18n.choose model.language { en = "WHY THIS APPROACH?", ru = "А ПОЧЕМУ ИМЕННО ТАК?" }) ], h2 [] [ text (I18n.choose model.language { en = "Ideas behind the practices, not magic.", ru = "За практиками — идеи, а не магия." }) ], p [] [ text (I18n.choose model.language { en = "Stoicism, phenomenology and psychoanalysis: three ways to look at tension. With an honest account of their limits.", ru = "Стоицизм, феноменология и психоанализ: три способа посмотреть на напряжение. И честный разговор об их границах." }) ] ]
            , button [ class "secondary-button", onClick (Navigated Why) ] [ text (I18n.choose model.language { en = "Explore ↗", ru = "Разобраться ↗" }) ]
            ]
        ]


viewCheckin : Model -> Html Msg
viewCheckin model =
    div []
        [ div [ class "section-heading" ] [ h2 [] [ text (I18n.choose model.language { en = "Inner weather", ru = "Внутренняя погода" }) ], span [ class "small-tag" ] [ text (I18n.choose model.language { en = "01 / NOTICE", ru = "01 / ЗАМЕТИТЬ" }) ] ]
        , p [ class "muted section-subtitle" ] [ text (I18n.choose model.language { en = "There is no right answer. There is yours.", ru = "Нет правильного ответа. Есть твой." }) ]
        , div [ class "level-display" ]
            [ div [] [ span [ class "level-number" ] [ text (String.fromInt (Domain.toInt model.level)) ], span [ class "level-denominator" ] [ text " / 10" ] ]
            , div [ class "level-copy" ] [ strong [] [ text (Content.levelLabel model.language model.level) ], span [] [ text (I18n.choose model.language { en = "Your subjective rating, not a diagnosis", ru = "Твоя субъективная оценка, не диагноз" }) ] ]
            ]
        , label [ class "sr-only", for "tension-level" ] [ text (I18n.choose model.language { en = "Tension level from 0 to 10", ru = "Уровень напряжения от 0 до 10" }) ]
        , input [ id "tension-level", class "tension-range", type_ "range", Html.Attributes.min "0", Html.Attributes.max "10", Html.Attributes.step "1", value (String.fromInt (Domain.toInt model.level)), onInput LevelChanged, disabled (model.saving == Saving), style "--level" (String.fromInt (Domain.toInt model.level * 10) ++ "%") ] []
        , div [ class "range-labels" ] [ span [] [ text (I18n.choose model.language { en = "0 — calm", ru = "0 — спокойно" }) ], span [] [ text (I18n.choose model.language { en = "10 — very tense", ru = "10 — очень напряжённо" }) ] ]
        , div [ class "field-heading" ] [ text (I18n.choose model.language { en = "What does it feel like?", ru = "На что это похоже?" }), span [] [ text (I18n.choose model.language { en = "choose more than one", ru = "можно несколько" }) ] ]
        , div [ class "feeling-list" ]
            (List.map
                (\feeling ->
                    button
                        [ class
                            (if List.member feeling model.feelings then
                                "feeling selected"

                             else
                                "feeling"
                            )
                        , onClick (FeelingToggled feeling)
                        , disabled (model.saving == Saving)
                        , attribute "aria-pressed"
                            (if List.member feeling model.feelings then
                                "true"

                             else
                                "false"
                            )
                        ]
                        [ text (Content.feelingLabel model.language feeling) ]
                )
                Domain.allFeelings
            )
        , label [ class "note-label", for "checkin-note" ] [ text (I18n.choose model.language { en = "What’s on your mind?", ru = "Что сейчас занимает тебя?" }), span [] [ text (I18n.choose model.language { en = "optional", ru = "необязательно" }) ] ]
        , textarea [ id "checkin-note", name "note", class "note-input", placeholder (I18n.choose model.language { en = "An event, a thought, a sensation… No explanation needed.", ru = "Событие, мысль, ощущение… Можно без объяснений." }), value model.note, onInput NoteChanged, maxlength 2000, disabled (model.saving == Saving), Html.Attributes.rows 2 ] []
        , div [ class "checkin-bottom" ]
            [ button [ class "primary-button", onClick SaveClicked, disabled (model.saving /= Editing || model.storage == Invalid || model.storage == ConflictDetected || model.deletion == Deleting) ]
                [ text
                    (case model.saving of
                        Editing ->
                            I18n.choose model.language { en = "Save this moment", ru = "Сохранить момент" }

                        Saving ->
                            I18n.choose model.language { en = "Saving…", ru = "Сохраняю…" }

                        Saved ->
                            I18n.choose model.language { en = "✓ Moment saved", ru = "✓ Момент записан" }
                    )
                , span [ attribute "aria-hidden" "true" ] [ text "↗" ]
                ]
            , span [ class "save-hint", attribute "role" "status" ]
                [ text
                    (if model.saving == Saved then
                        I18n.choose model.language { en = "You can change your answer and save another.", ru = "Можно изменить ответ и записать ещё." }

                     else
                        I18n.choose model.language { en = "Just for you", ru = "Только для тебя" }
                    )
                ]
            ]
        ]


viewPauseCard : Language -> Html Msg
viewPauseCard language =
    div []
        [ div [ class "pause-top" ] [ span [ class "eyebrow" ] [ text (I18n.choose language { en = "02 / PAUSE", ru = "02 / ВЫДОХНУТЬ" }) ], span [ class "time-tag" ] [ text (I18n.choose language { en = "~ 1 minute", ru = "~ 1 минута" }) ] ]
        , div [ class "orb-scene", attribute "aria-hidden" "true" ] [ div [ class "orb-orbit orbit-one" ] [], div [ class "orb-orbit orbit-two" ] [], div [ class "orb-orbit orbit-three" ] [], div [ class "orb-core" ] [], span [ class "orb-star" ] [ text "✧" ] ]
        , h2 [] [ text (I18n.choose language { en = "First, a little grounding.", ru = "Сначала — немного опоры." }) ]
        , p [] [ text (I18n.choose language { en = "No need to solve everything at once. Come back to what is here and now.", ru = "Не решать всё сразу. Вернуться к тому, что есть здесь и сейчас." }) ]
        , button [ class "light-button", onClick (PracticeSelected Presence) ] [ text (I18n.choose language { en = "Take a pause", ru = "Сделать паузу" }), span [ attribute "aria-hidden" "true" ] [ text "→" ] ]
        , p [ class "pause-footnote" ] [ text (I18n.choose language { en = "No breath-holding. At your own pace.", ru = "Без задержек дыхания. В своём темпе." }) ]
        ]


viewHistoryPreview : Model -> Html Msg
viewHistoryPreview model =
    let
        recent =
            List.take 7 model.entries |> List.reverse
    in
    div []
        [ div [ class "section-heading" ] [ h2 [] [ text (I18n.choose model.language { en = "How your state changes", ru = "Как меняется состояние" }) ], button [ class "inline-link", onClick (Navigated Journal) ] [ text (I18n.choose model.language { en = "Journal ↗", ru = "Дневник ↗" }) ] ]
        , if List.isEmpty recent then
            div [ class "empty-chart" ]
                [ div [ class "empty-chart-line", attribute "aria-hidden" "true" ] [ text "· · · · · · ·" ]
                , strong [] [ text (I18n.choose model.language { en = "Your own rhythm will appear here", ru = "Здесь появится твой ритм" }) ]
                , p [] [ text (I18n.choose model.language { en = "Save your first moment. We won’t invent data for you.", ru = "Сохрани первый момент. Мы не будем придумывать данные за тебя." }) ]
                ]

          else
            div []
                [ p [ class "muted section-subtitle" ] [ text (I18n.choose model.language { en = "Recent entries · not a measure of progress", ru = "Последние записи · не оценка прогресса" }) ]
                , div [ class "mini-chart", attribute "aria-label" (I18n.choose model.language { en = "Tension levels in recent entries", ru = "Уровень напряжения в последних записях" }) ]
                    (List.map
                        (\entry ->
                            div [ class "chart-column" ]
                                [ span [ class "chart-value" ] [ text (String.fromInt (Domain.toInt entry.level)) ]
                                , div [ class "chart-bar", style "height" (String.fromInt (8 + Domain.toInt entry.level * 7) ++ "px") ] []
                                , span [ class "chart-date" ] [ text (shortDate model.language model.zone (Time.millisToPosix entry.at)) ]
                                ]
                        )
                        recent
                    )
                , p [ class "chart-caption" ] [ text (I18n.choose model.language { en = "Fluctuations are natural. Reaching zero is not the goal.", ru = "Колебания естественны. Здесь нет цели дойти до нуля." }) ]
                ]
        ]


viewPractices : Model -> Html Msg
viewPractices model =
    let
        elapsed =
            Domain.timerElapsed model.timer

        currentStep =
            min 2 (elapsed // 20)

        prompt =
            Content.practiceSteps model.language model.practice |> List.drop currentStep |> List.head |> Maybe.withDefault (I18n.choose model.language { en = "You can stop here.", ru = "Можно завершить здесь." })
    in
    div [ class "page-inner" ]
        [ viewPageTitle (I18n.choose model.language { en = "FROM NOTICING TO A SMALL ACTION", ru = "ОТ ЗАМЕЧАНИЯ — К НЕБОЛЬШОМУ ДЕЙСТВИЮ" }) (I18n.choose model.language { en = "A little space.", ru = "Немного пространства." }) (I18n.choose model.language { en = "You can stop any practice. Your feelings don’t have to change.", ru = "Любую практику можно остановить. Чувства не обязаны измениться." })
        , div [ class "lens-tabs practice-groups", attribute "role" "group", attribute "aria-label" (I18n.choose model.language { en = "Practice group", ru = "Раздел практик" }) ]
            (List.map
                (\group ->
                    button
                        [ class
                            (if group == Domain.practiceGroup model.practice then
                                "lens-tab selected"

                             else
                                "lens-tab"
                            )
                        , attribute "aria-pressed"
                            (if group == Domain.practiceGroup model.practice then
                                "true"

                             else
                                "false"
                            )
                        , onClick
                            (PracticeSelected
                                (case group of
                                    Domain.Attention ->
                                        Presence

                                    Domain.Body ->
                                        ToeWalk
                                )
                            )
                        ]
                        [ text (Content.practiceGroupLabel model.language group) ]
                )
                Domain.allPracticeGroups
            )
        , div [ class "practice-options" ]
            (List.indexedMap
                (\index practice ->
                    button
                        [ class
                            (if practice == model.practice then
                                "practice-option selected"

                             else
                                "practice-option"
                            )
                        , onClick (PracticeSelected practice)
                        , attribute "aria-pressed"
                            (if practice == model.practice then
                                "true"

                             else
                                "false"
                            )
                        ]
                        [ span [ class "eyebrow" ] [ text (String.padLeft 2 '0' (String.fromInt (index + 1)) ++ I18n.choose model.language { en = " / YOUR OWN PACE", ru = " / СВОЙ ТЕМП" }) ], h3 [] [ text (Content.practiceLabel model.language practice) ], p [] [ text (Content.practiceDescription model.language practice) ] ]
                )
                (List.filter (\practice -> Domain.practiceGroup practice == Domain.practiceGroup model.practice) Domain.allPractices)
            )
        , section [ class "practice-player card" ]
            [ div [ class "timer-visual", style "--progress" (String.fromInt (elapsed * 6) ++ "deg") ]
                [ div [ class "timer-inner" ]
                    [ strong []
                        [ text
                            (if elapsed == 0 then
                                "1:00"

                             else
                                "0:" ++ String.padLeft 2 '0' (String.fromInt (60 - elapsed))
                            )
                        ]
                    , span []
                        [ text
                            (case model.timer of
                                Ready ->
                                    I18n.choose model.language { en = "at your own pace", ru = "в своём темпе" }

                                Starting ->
                                    I18n.choose model.language { en = "starting", ru = "начинаем" }

                                Running _ ->
                                    I18n.choose model.language { en = "no need to rush", ru = "можно не спешить" }

                                Paused _ ->
                                    I18n.choose model.language { en = "paused", ru = "пауза" }

                                Finished ->
                                    I18n.choose model.language { en = "enough", ru = "достаточно" }
                            )
                        ]
                    ]
                ]
            , div [ class "practice-instruction" ]
                [ p [ class "eyebrow" ]
                    [ text
                        (if model.timer == Finished then
                            I18n.choose model.language { en = "A MINUTE FOR YOURSELF", ru = "МИНУТА ДЛЯ СЕБЯ" }

                         else
                            I18n.choose model.language { en = "STEP ", ru = "ШАГ " } ++ String.fromInt (currentStep + 1) ++ I18n.choose model.language { en = " OF 3", ru = " ИЗ 3" }
                        )
                    ]
                , h2 [] [ text (Content.practiceLabel model.language model.practice) ]
                , p [ class "practice-precaution" ] [ text (Content.practicePrecaution model.language model.practice) ]
                , p [ class "practice-prompt", attribute "role" "status", attribute "aria-live" "polite" ]
                    [ text
                        (if model.timer == Finished then
                            I18n.choose model.language { en = "Notice how you feel now. Better, the same or worse — any answer is welcome. If you like, save a new moment.", ru = "Заметь, как тебе теперь. Лучше, так же или сложнее — любой ответ допустим. Если хочется, запиши новый момент." }

                         else
                            prompt
                        )
                    ]
                , div [ class "player-actions" ]
                    [ case model.timer of
                        Running _ ->
                            button [ class "primary-button", onClick PauseClicked ] [ text (I18n.choose model.language { en = "Pause Ⅱ", ru = "Приостановить Ⅱ" }) ]

                        Starting ->
                            button [ class "primary-button", disabled True ] [ text (I18n.choose model.language { en = "Starting…", ru = "Начинаем…" }) ]

                        Paused _ ->
                            button [ class "primary-button", onClick StartClicked ] [ text (I18n.choose model.language { en = "Continue →", ru = "Продолжить →" }) ]

                        Finished ->
                            button [ class "primary-button", onClick (Navigated Today) ] [ text (I18n.choose model.language { en = "How am I now? →", ru = "Как я сейчас? →" }) ]

                        Ready ->
                            button [ class "primary-button", onClick StartClicked ] [ text (I18n.choose model.language { en = "Start practice →", ru = "Начать практику →" }) ]
                    , button [ class "secondary-button", onClick ResetClicked, disabled (model.timer == Ready) ] [ text (I18n.choose model.language { en = "Finish / reset", ru = "Завершить / сбросить" }) ]
                    ]
                ]
            ]
        , section [ class "card practice-guide" ]
            [ h2 [] [ text (I18n.choose model.language { en = "No timer needed", ru = "Можно и без таймера" }) ]
            , div [ class "steps-grid" ] (List.indexedMap (\index step -> div [] [ span [ class "step-number" ] [ text ("0" ++ String.fromInt (index + 1)) ], p [] [ text step ] ]) (Content.practiceSteps model.language model.practice))
            , p [ class "safety-note" ] [ text (I18n.choose model.language { en = "A minute is an interface guide, not a required duration or a promise of results. Read all the steps first: walking and movement do not need a timer. Stop if you feel pain, dizziness or unwell. If you have an injury, recent surgery or medical restrictions, check with a qualified professional before movements or massage that affect them. These are original self-observation practices, not treatment.", ru = "Минута — ориентир интерфейса, не обязательная длительность и не обещание результата. Сначала прочитай все шаги: для прогулки и движений таймер не нужен. При боли, головокружении или ухудшении самочувствия остановись. При травме, недавней операции или медицинских ограничениях не выполняй затрагивающие их движения и массаж без согласования со специалистом. Это авторские практики самонаблюдения, не лечение." }) ]
            ]
        ]


viewJournal : Model -> Html Msg
viewJournal model =
    let
        days =
            case model.range of
                Week ->
                    Just 7

                Month ->
                    Just 30

                AllTime ->
                    Nothing

        entries =
            case days of
                Nothing ->
                    model.entries

                Just count ->
                    List.filter (\entry -> entry.at >= Time.posixToMillis model.now - count * 86400000) model.entries
    in
    div [ class "page-inner" ]
        [ viewPageTitle (I18n.choose model.language { en = "NO STREAKS, RECORDS OR RIGHT ANSWERS", ru = "БЕЗ СЕРИЙ, РЕКОРДОВ И ПРАВИЛЬНЫХ ОТВЕТОВ" }) (I18n.choose model.language { en = "A journal of observations.", ru = "Дневник наблюдений." }) (I18n.choose model.language { en = "Not a productivity report. Traces of what you’ve been experiencing.", ru = "Не отчёт о продуктивности. Следы того, что с тобой происходило." })
        , div [ class "journal-toolbar" ]
            [ div [ class "lens-tabs", attribute "aria-label" (I18n.choose model.language { en = "Entry date range", ru = "Период записей" }) ]
                (List.map
                    (\( range, caption ) ->
                        button
                            [ class
                                (if model.range == range then
                                    "lens-tab selected"

                                 else
                                    "lens-tab"
                                )
                            , onClick (RangeSelected range)
                            , attribute "aria-pressed"
                                (if model.range == range then
                                    "true"

                                 else
                                    "false"
                                )
                            ]
                            [ text caption ]
                    )
                    [ ( Week, I18n.choose model.language { en = "7 days", ru = "7 дней" } ), ( Month, I18n.choose model.language { en = "30 days", ru = "30 дней" } ), ( AllTime, I18n.choose model.language { en = "All time", ru = "Всё время" } ) ]
                )
            , button [ class "secondary-button", onClick ExportClicked, disabled (List.isEmpty model.entries) ] [ text (I18n.choose model.language { en = "Download JSON ↓", ru = "Скачать JSON ↓" }) ]
            ]
        , p [ class "muted journal-count" ] [ text (I18n.choose model.language { en = "Entries in this period: ", ru = "Записей за период: " } ++ String.fromInt (List.length entries)) ]
        , if List.isEmpty entries then
            section [ class "card journal-empty" ] [ span [ class "empty-symbol", attribute "aria-hidden" "true" ] [ text "▤" ], h2 [] [ text (I18n.choose model.language { en = "A blank page for now", ru = "Пока чистая страница" }) ], p [] [ text (I18n.choose model.language { en = "No entries in this period. You can start with a thought or just a number.", ru = "За этот период записей нет. Можно начать с одной мысли или просто числа." }) ], button [ class "primary-button", onClick (Navigated Today) ] [ text (I18n.choose model.language { en = "Notice how you feel →", ru = "Заметить своё состояние →" }) ] ]

          else
            div [ class "journal-list" ] (List.map (viewEntry model.language model.zone) entries)
        , section [ class "privacy-panel" ]
            [ div [] [ h3 [] [ text (I18n.choose model.language { en = "Your entries belong to you", ru = "Твои записи принадлежат тебе" }) ], p [] [ text (I18n.choose model.language { en = "Stored in this browser’s localStorage, without encryption. Other people using a shared device may read them. Clearing browser data deletes the entries; download a copy if you want to keep them.", ru = "Хранятся в localStorage этого браузера, без шифрования. На общем устройстве их могут прочитать другие. Очистка браузера удалит записи; скачай копию, если хочешь их сохранить." }) ] ]
            , if model.deletion /= NotDeleting then
                div [ class "delete-confirm", attribute "role" "alert" ]
                    [ strong [] [ text (I18n.choose model.language { en = "Permanently delete all entries?", ru = "Удалить все записи без возможности отмены?" }) ]
                    , div [ class "player-actions" ]
                        [ button [ class "danger-button", onClick DeleteConfirmed, disabled (model.deletion == Deleting) ]
                            [ text
                                (if model.deletion == Deleting then
                                    I18n.choose model.language { en = "Deleting…", ru = "Удаляю…" }

                                 else
                                    I18n.choose model.language { en = "Yes, delete everything", ru = "Да, удалить всё" }
                                )
                            ]
                        , button [ class "secondary-button", onClick DeleteCancelled, disabled (model.deletion == Deleting) ] [ text (I18n.choose model.language { en = "Cancel", ru = "Отмена" }) ]
                        ]
                    ]

              else
                button [ class "danger-link", onClick DeleteRequested, disabled (model.saving == Saving || (List.isEmpty model.entries && model.storage /= Invalid)) ] [ text (I18n.choose model.language { en = "Delete all data", ru = "Удалить все данные" }) ]
            ]
        ]


viewEntry : Language -> Time.Zone -> Entry -> Html Msg
viewEntry language zone entry =
    section [ class "card journal-entry" ]
        [ div [ class "entry-level" ] [ strong [] [ text (String.fromInt (Domain.toInt entry.level)) ], span [] [ text "/ 10" ] ]
        , div [ class "entry-body" ]
            [ div [ class "section-heading" ] [ strong [] [ text (Content.levelLabel language entry.level) ], span [ class "entry-date" ] [ text (formatDate language zone (Time.millisToPosix entry.at) ++ " · " ++ formatTime zone (Time.millisToPosix entry.at)) ] ]
            , div [ class "entry-feelings" ] (List.map (\feeling -> span [ class "small-tag" ] [ text (Content.feelingLabel language feeling) ]) entry.feelings)
            , if String.isEmpty entry.note then
                text ""

              else
                p [ class "entry-note" ] [ text entry.note ]
            ]
        ]


monthName : Language -> Time.Month -> String
monthName language month =
    case month of
        Time.Jan ->
            I18n.choose language { en = "January", ru = "января" }

        Time.Feb ->
            I18n.choose language { en = "February", ru = "февраля" }

        Time.Mar ->
            I18n.choose language { en = "March", ru = "марта" }

        Time.Apr ->
            I18n.choose language { en = "April", ru = "апреля" }

        Time.May ->
            I18n.choose language { en = "May", ru = "мая" }

        Time.Jun ->
            I18n.choose language { en = "June", ru = "июня" }

        Time.Jul ->
            I18n.choose language { en = "July", ru = "июля" }

        Time.Aug ->
            I18n.choose language { en = "August", ru = "августа" }

        Time.Sep ->
            I18n.choose language { en = "September", ru = "сентября" }

        Time.Oct ->
            I18n.choose language { en = "October", ru = "октября" }

        Time.Nov ->
            I18n.choose language { en = "November", ru = "ноября" }

        Time.Dec ->
            I18n.choose language { en = "December", ru = "декабря" }


formatDate : Language -> Time.Zone -> Time.Posix -> String
formatDate language zone date =
    String.fromInt (Time.toDay zone date) ++ " " ++ monthName language (Time.toMonth zone date) ++ " " ++ String.fromInt (Time.toYear zone date)


shortDate : Language -> Time.Zone -> Time.Posix -> String
shortDate language zone date =
    String.fromInt (Time.toDay zone date) ++ " " ++ String.left 3 (monthName language (Time.toMonth zone date))


formatTime : Time.Zone -> Time.Posix -> String
formatTime zone date =
    String.padLeft 2 '0' (String.fromInt (Time.toHour zone date)) ++ ":" ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute zone date))
