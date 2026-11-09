module Content exposing (feelingLabel, levelLabel, practiceDescription, practiceGroupLabel, practiceLabel, practicePrecaution, practiceSteps)

import Domain exposing (Feeling(..), Level, Practice(..), PracticeGroup(..))
import I18n exposing (Language)


levelLabel : Language -> Level -> String
levelLabel language level =
    let
        value =
            Domain.toInt level
    in
    if value <= 3 then
        I18n.choose language { en = "There is a little space", ru = "Есть немного пространства" }

    else if value <= 6 then
        I18n.choose language { en = "Tension is noticeable", ru = "Напряжение ощутимо" }

    else
        I18n.choose language { en = "High tension", ru = "Высокое напряжение" }


feelingLabel : Language -> Feeling -> String
feelingLabel language feeling =
    case feeling of
        Anxiety ->
            I18n.choose language { en = "Anxiety", ru = "Тревога" }

        Anger ->
            I18n.choose language { en = "Anger", ru = "Злость" }

        Fatigue ->
            I18n.choose language { en = "Fatigue", ru = "Усталость" }

        Sadness ->
            I18n.choose language { en = "Sadness", ru = "Грусть" }

        Confusion ->
            I18n.choose language { en = "Confusion", ru = "Растерянность" }

        Calm ->
            I18n.choose language { en = "Calm", ru = "Спокойствие" }


practiceGroupLabel : Language -> PracticeGroup -> String
practiceGroupLabel language group =
    case group of
        Attention ->
            I18n.choose language { en = "Attention and choice", ru = "Внимание и выбор" }

        Body ->
            I18n.choose language { en = "Body and movement", ru = "Тело и движение" }


practiceLabel : Language -> Practice -> String
practiceLabel language practice =
    case practice of
        Presence ->
            I18n.choose language { en = "Return to the present", ru = "Вернуться в настоящее" }

        Control ->
            I18n.choose language { en = "Find your footing", ru = "Найти свою опору" }

        Conflict ->
            I18n.choose language { en = "Make room for mixed feelings", ru = "Дать место противоречию" }

        ToeWalk ->
            I18n.choose language { en = "Walk on your toes", ru = "Пройти на носках" }

        CrownReach ->
            I18n.choose language { en = "Reach up through your crown", ru = "Потянуться макушкой вверх" }

        SensoryWalk ->
            I18n.choose language { en = "Take a sensory walk", ru = "Прогуляться с вниманием" }

        BodyContact ->
            I18n.choose language { en = "Explore touch on your body", ru = "Пройтись руками по телу" }

        FingerTapping ->
            I18n.choose language { en = "Tap with your fingertips", ru = "Постучать подушечками пальцев" }

        SelfMassage ->
            I18n.choose language { en = "Massage your muscles by hand", ru = "Размять мышцы своими руками" }

        HeadMassage ->
            I18n.choose language { en = "Massage your head and face", ru = "Помассировать голову и лицо" }

        Breathing ->
            I18n.choose language { en = "Feel your breathing move", ru = "Почувствовать движение дыхания" }

        WarmPalms ->
            I18n.choose language { en = "Shade your eyes with your palms", ru = "Прикрыть глаза ладонями" }


practiceDescription : Language -> Practice -> String
practiceDescription language practice =
    case practice of
        Presence ->
            I18n.choose language { en = "From explanations to what you can notice right now.", ru = "От объяснений — к тому, что прямо сейчас можно заметить." }

        Control ->
            I18n.choose language { en = "Separate the circumstances from your next small step.", ru = "Разделить обстоятельства и свой следующий небольшой шаг." }

        Conflict ->
            I18n.choose language { en = "Hear two wishes without forcing yourself to choose right away.", ru = "Услышать два желания, не заставляя себя немедленно выбирать." }

        ToeWalk ->
            I18n.choose language { en = "Lift your heels, take a few steps and feel your whole foot again.", ru = "Поднять пятки, сделать несколько шагов и снова почувствовать всю стопу." }

        CrownReach ->
            I18n.choose language { en = "Reach upward without tilting your head back, and notice your muscles working.", ru = "Потянуться вверх без запрокидывания головы и заметить работу мышц." }

        SensoryWalk ->
            I18n.choose language { en = "Look around, distinguish sounds and feel your clothes and shoes.", ru = "Посмотреть вокруг, различить звуки и почувствовать одежду и обувь." }

        BodyContact ->
            I18n.choose language { en = "Use your palms to explore accessible areas of your body, starting at your feet.", ru = "Своими ладонями пройти от стоп вверх по доступным участкам тела." }

        FingerTapping ->
            I18n.choose language { en = "Tap your arms and legs with your fingertips, varying the rhythm.", ru = "Простучать руки и ноги подушечками пальцев, меняя ритм." }

        SelfMassage ->
            I18n.choose language { en = "Massage your forearms, shoulders and the back of your neck — no gadgets.", ru = "Размять предплечья, плечи и заднюю поверхность шеи — без гаджетов." }

        HeadMassage ->
            I18n.choose language { en = "Use your fingers on your scalp, forehead, brow ridges and ears.", ru = "Поработать пальцами с кожей головы, лбом, бровными дугами и ушами." }

        Breathing ->
            I18n.choose language { en = "Feel with your palms how your belly and ribs move as you breathe.", ru = "Почувствовать ладонями, как на вдохе и выдохе двигаются живот и рёбра." }

        WarmPalms ->
            I18n.choose language { en = "Rub your palms together for warmth and block out light without pressing on your eyes.", ru = "Согреть ладони трением и закрыть ими свет, не нажимая на глаза." }


practicePrecaution : Language -> Practice -> String
practicePrecaution language practice =
    case practice of
        Presence ->
            I18n.choose language { en = "You can keep your eyes open. No need to change your breathing or try to become calm.", ru = "Глаза можно оставить открытыми. Не нужно менять дыхание или добиваться спокойствия." }

        Control ->
            I18n.choose language { en = "Having a choice does not make you responsible for other people’s actions. You don’t have to solve everything now.", ru = "Доступный выбор не означает ответственность за чужие поступки. Не нужно решать всё сейчас." }

        Conflict ->
            I18n.choose language { en = "No need to seek out traumatic memories. If the question feels overwhelming, you can stop.", ru = "Не нужно искать травматичные воспоминания. Если вопрос перегружает, можно не продолжать." }

        ToeWalk ->
            I18n.choose language { en = "You need a level, non-slip floor and a stable support nearby. Stop if you feel pain or unsteady; you can stay seated and lift your heels instead.", ru = "Нужны ровный нескользкий пол и устойчивая опора рядом. При боли или неустойчивости не продолжай; можно остаться сидеть и приподнять пятки." }

        CrownReach ->
            I18n.choose language { en = "Do not pull your head with your hands, tilt it back or let it hang off a bed. Stop if you feel pain or dizziness.", ru = "Не тяни голову руками, не запрокидывай её и не свешивай с кровати. При боли или головокружении остановись." }

        SensoryWalk ->
            I18n.choose language { en = "Read the steps first, then put your phone away. Watch where you are going; near crossings and traffic, your surroundings need your attention, not the exercise.", ru = "Сначала прочитай шаги, затем убери телефон. Смотри на дорогу; у переходов и транспорта внимание нужно обстановке, не упражнению." }

        BodyContact ->
            I18n.choose language { en = "Do not press on painful, injured or irritated areas. You don’t have to reach your whole body or tolerate unpleasant touch.", ru = "Не дави на болезненные, травмированные или раздражённые участки. Не нужно доставать до всего тела или терпеть неприятное прикосновение." }

        FingerTapping ->
            I18n.choose language { en = "Tap with your fingertips, not your fists. Do not tap your head, neck, injured areas or bruises.", ru = "Это постукивание подушечками, не удары кулаком. Не простукивай голову, шею, повреждённые участки и места с синяками." }

        SelfMassage ->
            I18n.choose language { en = "Do not press on your spine or the front and sides of your neck. Avoid injured or inflamed areas; pain is not the goal.", ru = "Не дави на позвоночник, переднюю и боковые поверхности шеи. Не разминай повреждённые или воспалённые участки; боль не цель." }

        HeadMassage ->
            I18n.choose language { en = "Do not press on your eyeballs or eyelids. Do not rub until your skin hurts or burns; skip inflamed or injured areas.", ru = "Не нажимай на глазные яблоки и веки. Не растирай кожу до боли или жжения; воспалённые и повреждённые участки пропусти." }

        Breathing ->
            I18n.choose language { en = "No breath-holding, sudden breaths or extremely deep inhalations. No need to make your belly and chest move in a strict sequence. If you feel dizzy or short of breath, stop and return to your usual breathing.", ru = "Без задержек, резких и предельно глубоких вдохов. Не нужно добиваться строгой очередности живота и груди. При головокружении или нехватке воздуха прекрати упражнение и вернись к обычному дыханию." }

        WarmPalms ->
            I18n.choose language { en = "Your palms should be clean and warm, not hot. No pressure on your eyes and no required duration; skip this practice if your eyes hurt.", ru = "Ладони должны быть чистыми и тёплыми, не горячими. Никакого давления на глаза и обязательного времени; если глазам больно, не выполняй практику." }


practiceSteps : Language -> Practice -> List String
practiceSteps language practice =
    case practice of
        Presence ->
            [ I18n.choose language { en = "Look around. Silently name three objects and their colours.", ru = "Посмотри вокруг. Назови про себя три предмета и их цвета." }
            , I18n.choose language { en = "Feel the support under your feet or back. No need to change your breathing.", ru = "Почувствуй опору под ногами или спиной. Не нужно менять дыхание." }
            , I18n.choose language { en = "Notice one sound. Ask yourself: what might help right now — water, quiet, movement?", ru = "Заметь один звук. Спроси себя: что мне сейчас поможет — вода, тишина, движение?" }
            ]

        Control ->
            [ I18n.choose language { en = "Name one situation that is on your mind right now.", ru = "Назови одну ситуацию, которая сейчас занимает твои мысли." }
            , I18n.choose language { en = "What here is outside your control? What small action is available to you?", ru = "Что здесь не зависит от тебя? А какой маленький поступок доступен тебе?" }
            , I18n.choose language { en = "Choose a manageable step: ask a question, pause or ask for help. Not everything needs to be solved now.", ru = "Выбери посильный шаг: задать вопрос, сделать паузу или попросить помощи. Не всё нужно решать сейчас." }
            ]

        Conflict ->
            [ I18n.choose language { en = "If you have the energy: finish the sentence ‘One part of me wants…’. You can stop there.", ru = "Если сейчас есть силы: закончи фразу «Одна часть меня хочет…». Можно не продолжать." }
            , I18n.choose language { en = "What does another part want or fear? Both answers may make sense.", ru = "А другая часть чего хочет или чего опасается? Оба ответа могут иметь смысл." }
            , I18n.choose language { en = "What could offer you a little care without requiring the whole conflict to be resolved?", ru = "Что могло бы немного позаботиться о тебе, не требуя разрешить весь конфликт?" }
            ]

        ToeWalk ->
            [ I18n.choose language { en = "Stand beside a stable support on a level, non-slip floor. Hold it while lifting and lowering your heels a few times.", ru = "Встань рядом с устойчивой опорой на ровном нескользком полу. Держась за неё, подними и опусти пятки несколько раз." }
            , I18n.choose language { en = "If you feel steady, take a few small steps on your toes alongside the support. Feel your feet and calves working; do not try to rise as high as possible.", ru = "Если стоишь уверенно, сделай несколько небольших шагов на носках вдоль опоры. Почувствуй работу стоп и икр; не пытайся подняться как можно выше." }
            , I18n.choose language { en = "Lower your heels and stand on your whole feet. Compare the support before and after. If standing is uncomfortable, you can lift your heels while seated.", ru = "Опусти пятки и постой на всей стопе. Сравни опору до и после. Если стоять неудобно, можно сделать подъёмы пяток сидя." }
            ]

        CrownReach ->
            [ I18n.choose language { en = "Sit or stand with your feet supported. Look ahead and keep your chin in its usual position.", ru = "Сядь или встань с опорой под стопами. Смотри перед собой, оставь подбородок в привычном положении." }
            , I18n.choose language { en = "Reach upward through the crown of your head, as if becoming a little taller. Do not raise your shoulders or hold your breath. Then release the effort.", ru = "Потянись макушкой вверх, словно хочешь стать чуть выше. Не поднимай плечи и не задерживай дыхание. Затем отпусти усилие." }
            , I18n.choose language { en = "Repeat a few times within a comfortable range. Notice any changes in your back, shoulders and the support under your feet.", ru = "Повтори несколько раз в удобной амплитуде. Заметь, как меняются ощущения в спине, плечах и опоре под стопами." }
            ]

        SensoryWalk ->
            [ I18n.choose language { en = "Read all the steps before your walk and put your phone away. Walk along a familiar, safe route; notice the path, objects and colours around you.", ru = "Прочитай все шаги до прогулки и убери телефон. Иди по знакомому безопасному участку; замечай дорогу, предметы и цвета вокруг." }
            , I18n.choose language { en = "Feel your clothes on your skin and shoes on your feet. How does the pressure change with each step? No need to slow down to an uncomfortable pace.", ru = "Почувствуй одежду на коже и обувь на стопах. Как меняется давление при каждом шаге? Не нужно замедляться до неудобного темпа." }
            , I18n.choose language { en = "Distinguish a few sounds: footsteps, wind, voices. How does a creaking door differ from a creaking tree? Don’t look it up on your phone — listen to what is nearby.", ru = "Различи несколько звуков: шаги, ветер, голоса. Чем скрип двери отличается от скрипа дерева? Не ищи ответ в телефоне — послушай, что есть рядом." }
            ]

        BodyContact ->
            [ I18n.choose language { en = "Sit comfortably and start with your feet or another accessible area. Hold it in your palms and move your hands over skin or clothing.", ru = "Сядь удобно и начни со стоп или другого доступного участка. Обхвати его своими ладонями, проведи по коже или одежде." }
            , I18n.choose language { en = "Move upward: lower legs, thighs, belly, arms, shoulders — only where touch feels comfortable. Vary the area of contact without pressing hard enough to hurt.", ru = "Продвигайся вверх: голени, бёдра, живот, руки, плечи — только там, где прикосновение удобно. Меняй площадь контакта, не усиливая давление до боли." }
            , I18n.choose language { en = "Rest your palms on an area you would like to give a little more attention. Notice temperature, pressure and the outline of your body; no need to cover everything.", ru = "Положи ладони на участок, которому хочется уделить ещё немного внимания. Заметь температуру, давление и границы тела; охватить всё не обязательно." }
            ]

        FingerTapping ->
            [ I18n.choose language { en = "Relax your hand and tap the other forearm with your fingertips. Find contact you can clearly feel without pain.", ru = "Расслабь кисть и постучи подушечками пальцев по предплечью другой руки. Найди отчётливо ощутимый, но безболезненный контакт." }
            , I18n.choose language { en = "Move along your arms and thighs. Try another rhythm: fingers one at a time or several together. Keep it tapping, not hitting.", ru = "Пройди по рукам и бёдрам. Попробуй другой ритм: по очереди пальцами или несколькими сразу. Не превращай постукивание в удары." }
            , I18n.choose language { en = "Stop tapping and place your palm on that area. Compare the sensations during the rhythm and afterwards.", ru = "Останови пальцы и приложи ладонь к этому месту. Сравни ощущения во время ритма и после него." }
            ]

        SelfMassage ->
            [ I18n.choose language { en = "Hold one forearm with your other hand. Massage the muscles with your fingers and palm, then switch hands. No massagers or deep pressure.", ru = "Своей рукой обхвати предплечье другой руки. Разомни мышцы пальцами и ладонью, затем поменяй руки. Без массажёров и сильного продавливания." }
            , I18n.choose language { en = "Massage the accessible upper part of your shoulder. If comfortable, move your fingers along the muscles at the back of your neck, without pressing on your spine or forcing your head to turn.", ru = "Разомни доступную верхнюю часть плеча. Если удобно, проведи пальцами по мышцам сзади шеи, не надавливая на позвоночник и не поворачивая голову через усилие." }
            , I18n.choose language { en = "Lower your hands and move your shoulders within their usual range. Compare the sensations; no need to seek out painful spots or massage through pain.", ru = "Убери руки и подвигай плечами в привычном диапазоне. Сравни ощущения; не нужно искать болезненные точки или разминать их через боль." }
            ]

        HeadMassage ->
            [ I18n.choose language { en = "Make small circular movements on your scalp with your fingertips, like a whisk. Move to your forehead and hairline without scratching your skin.", ru = "Подушечками пальцев делай небольшие круговые движения по коже головы, как венчиком. Перейди ко лбу и линии роста волос, не царапая кожу." }
            , I18n.choose language { en = "Move your fingers along the bony brow ridges, staying above the eye sockets. Do not press on your eyelids or eyeballs.", ru = "Проведи пальцами по костному краю бровных дуг, оставаясь выше глазниц. Не надавливай на веки и глазные яблоки." }
            , I18n.choose language { en = "Rub your outer ears and earlobes between your fingers until comfortably warm, not burning. Lower your hands and compare the sensations.", ru = "Разотри ушные раковины и мочки между пальцами до комфортного ощущения тепла, не до жжения. Отпусти руки и сравни ощущения." }
            ]

        Breathing ->
            [ I18n.choose language { en = "Sit with support or lie down comfortably. Place one palm on your belly and the other on your chest. First feel a few ordinary breaths.", ru = "Сядь с опорой или ляг удобно. Одну ладонь положи на живот, другую — на грудную клетку. Сначала почувствуй несколько обычных вдохов." }
            , I18n.choose language { en = "On your next comfortable inhalation, let your belly expand, then notice your ribs moving. Do not fill up to your limit or hold your breath. Air goes into your lungs; your palms notice your body moving.", ru = "На следующем удобном вдохе дай животу расшириться, затем заметь движение рёбер. Не набирай воздух до предела и не задерживай его. Воздух идёт в лёгкие, а ладони замечают движение тела." }
            , I18n.choose language { en = "As you breathe out without effort, feel your ribs and belly lower. Repeat at your own pace, without aiming for a strict sequence or deeper breathing.", ru = "Выдыхая без усилия, почувствуй, как опускаются рёбра и живот. Повтори в своём ритме, не добиваясь строгой очередности или более глубокого дыхания." }
            ]

        WarmPalms ->
            [ I18n.choose language { en = "Rub your clean palms together until pleasantly warm. Sit so that you can support your elbows.", ru = "Потри чистые ладони друг о друга, пока они не станут приятно тёплыми. Сядь так, чтобы локти можно было опереть." }
            , I18n.choose language { en = "Close your eyes and cup your palms in front of them to block out light. Your palms do not touch your eyes or press on your eyelids; breathe as usual.", ru = "Закрой глаза и сложи ладони чашечками перед ними, перекрыв свет. Ладони не касаются глаз и не давят на веки; дыши как обычно." }
            , I18n.choose language { en = "Stay as long as comfortable, then lower your hands and open your eyes. The timer is only a guide: you can finish sooner or continue without it.", ru = "Останься так, пока удобно, затем убери руки и открой глаза. Таймер — только ориентир: можно закончить раньше или продолжить без него." }
            ]
