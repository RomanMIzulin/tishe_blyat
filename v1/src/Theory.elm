module Theory exposing (Lens(..), all, description, label, source, title, view)

import Html exposing (Html, a, article, button, details, div, h2, h3, li, p, span, summary, text, ul)
import Html.Attributes exposing (attribute, class, href)
import Html.Events exposing (onClick)
import I18n exposing (Language)


type Lens
    = Stoic
    | Phenomenology
    | Psychoanalysis


all : List Lens
all =
    [ Stoic, Phenomenology, Psychoanalysis ]


label : Language -> Lens -> String
label language lens =
    case lens of
        Stoic ->
            I18n.choose language { en = "Stoicism", ru = "Стоицизм" }

        Phenomenology ->
            I18n.choose language { en = "Phenomenology", ru = "Феноменология" }

        Psychoanalysis ->
            I18n.choose language { en = "Psychoanalysis", ru = "Психоанализ" }


title : Language -> Lens -> String
title language lens =
    case lens of
        Stoic ->
            I18n.choose language { en = "You can’t control everything. You can choose your next step.", ru = "Не всем управлять. Выбирать свой шаг." }

        Phenomenology ->
            I18n.choose language { en = "Notice first. Explain later.", ru = "Сначала заметить. Потом объяснять." }

        Psychoanalysis ->
            I18n.choose language { en = "There can be more than one wish inside.", ru = "Внутри может быть больше одного желания." }


description : Language -> Lens -> String
description language lens =
    case lens of
        Stoic ->
            I18n.choose language { en = "We cannot guarantee someone else’s response or a good outcome. But we can look for choices available to us: ask for help, set a boundary, take a pause. This is not a demand to tolerate injustice or blame yourself for your feelings.", ru = "Мы не можем гарантировать чужой ответ или удачный исход. Но можем искать доступный нам выбор: попросить о помощи, обозначить границу, сделать паузу. Это не требование терпеть несправедливость или обвинять себя за чувства." }

        Phenomenology ->
            I18n.choose language { en = "Instead of ‘something is wrong with me’, you can start with a description: ‘I notice anxiety and an urge to check everything again’. This pause between experience and explanation is inspired by phenomenology, but is not its rigorous method.", ru = "Вместо «со мной что-то не так» можно начать с описания: «я замечаю тревогу и желание всё перепроверить». Такая пауза между переживанием и объяснением вдохновлена феноменологией, но не является её строгим методом." }

        Psychoanalysis ->
            I18n.choose language { en = "Tension can sometimes be explored as a clash of wishes: wanting closeness while fearing rejection. A familiar reaction may serve a protective function. This is a possible question to ask yourself, not a hidden truth established by the app.", ru = "Напряжение иногда можно рассмотреть как столкновение желаний: хочется близости — и страшно быть отвергнутым. Привычная реакция может выполнять защитную функцию. Это возможный вопрос к себе, а не скрытая истина, установленная приложением." }


source : Language -> Lens -> String
source language lens =
    case lens of
        Stoic ->
            I18n.choose language { en = "Epictetus · Enchiridion, § 1. Distinguishing what is and is not within our control. The exercise is a modern adaptation, not a quotation.", ru = "Эпиктет · «Руководство», § 1. Различение зависящего и не зависящего от нас. Упражнение — современная адаптация, не цитата." }

        Phenomenology ->
            I18n.choose language { en = "Edmund Husserl · Ideas Pertaining to a Pure Phenomenology…, Book I, §§ 27–32. The natural attitude and its suspension. Our exercise is not equivalent to phenomenological reduction.", ru = "Эдмунд Гуссерль · «Идеи к чистой феноменологии…», книга I, §§ 27–32. Естественная установка и её выключение. Наше упражнение не равно феноменологической редукции." }

        Psychoanalysis ->
            I18n.choose language { en = "Sigmund Freud · Introductory Lectures on Psycho-Analysis, Lecture 23: ‘The Paths to the Formation of Symptoms’; Inhibitions, Symptoms and Anxiety (1926). Historical foundations for the ideas of conflict and defence, not confirmation of the cause of your state.", ru = "Зигмунд Фрейд · «Лекции по введению в психоанализ», лекция 23: «Пути образования симптомов»; «Торможение, симптом и тревога» (1926). Исторические основания понятий конфликта и защиты, не подтверждение причины вашего состояния." }


view : Language -> Lens -> (Lens -> msg) -> Html msg
view language selected select =
    div [ class "theory-content" ]
        [ div [ class "section-heading" ]
            [ div [] [ p [ class "eyebrow" ] [ text (I18n.choose language { en = "WHY / FOUNDATIONS", ru = "WHY / ОСНОВАНИЯ" }) ], h2 [] [ text (I18n.choose language { en = "Not fixing yourself. Understanding.", ru = "Не исправлять себя. Понимать." }) ] ]
            , span [ class "small-tag" ] [ text (I18n.choose language { en = "3 perspectives", ru = "3 оптики" }) ]
            ]
        , p [ class "intro-copy" ] [ text (I18n.choose language { en = "Philosophy helps us ask questions. Psychoanalysis leaves room for ambiguity. Neither approach asks you to stop feeling.", ru = "Философия помогает задать вопрос. Психоанализ — допустить неоднозначность. Ни один подход не требует перестать чувствовать." }) ]
        , div [ class "lens-tabs", attribute "aria-label" (I18n.choose language { en = "Theoretical approach", ru = "Теоретический подход" }) ]
            (List.map
                (\lens ->
                    button
                        [ class
                            (if lens == selected then
                                "lens-tab selected"

                             else
                                "lens-tab"
                            )
                        , onClick (select lens)
                        , attribute "aria-pressed"
                            (if lens == selected then
                                "true"

                             else
                                "false"
                            )
                        ]
                        [ text (label language lens) ]
                )
                all
            )
        , article [ class "theory-article" ]
            [ span [ class "theory-symbol", attribute "aria-hidden" "true" ] [ text "∴" ]
            , div []
                [ h3 [] [ text (title language selected) ]
                , p [] [ text (description language selected) ]
                , p [ class "source" ] [ text (source language selected) ]
                ]
            ]
        , div [ class "theory-boundary" ]
            [ h3 [] [ text (I18n.choose language { en = "Theory is not a promise of results", ru = "Теория — не обещание результата" }) ]
            , p [] [ text (I18n.choose language { en = "These are three different approaches, not a single proven therapy. Bringing them together here is an original interpretation for self-exploration. The app has not been clinically tested: we do not promise to reduce tension or make diagnoses.", ru = "Это три разных подхода, а не единая доказанная терапия. Их соединение здесь — авторская интерпретация для самоисследования. У приложения нет клинической проверки: мы не обещаем снижение напряжения и не ставим диагнозы." }) ]
            ]
        , details [ class "safety-details" ]
            [ summary [] [ text (I18n.choose language { en = "When is it better to stop a practice?", ru = "Когда практику лучше остановить?" }) ]
            , ul []
                [ li [] [ text (I18n.choose language { en = "If a question or exercise feels unpleasant, you can stop, skip a step or choose another practice. You don’t have to complete everything on the timer.", ru = "Если вопрос или упражнение неприятны, можно остановиться, пропустить шаг или выбрать другую практику. Завершать всё по таймеру не обязательно." }) ]
                , li [] [ text (I18n.choose language { en = "No need to close your eyes, change your breathing or seek a hidden cause for every feeling. Choose a time when nothing else needs your attention.", ru = "Не нужно закрывать глаза, менять дыхание или искать скрытую причину каждого чувства. Для практики выбери время, когда ничто не требует твоего внимания." }) ]
                ]
            ]
        , a [ class "text-link", href "https://en.wikisource.org/wiki/Enchiridion_(Epictetus)" ] [ text (I18n.choose language { en = "Epictetus: primary source ↗", ru = "Эпиктет: первоисточник ↗" }) ]
        ]
