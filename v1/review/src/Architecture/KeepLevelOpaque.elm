module Architecture.KeepLevelOpaque exposing (rule)

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Exposing as Exposing
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchema "Architecture.KeepLevelOpaque" OutsideDomain
        |> Rule.withModuleDefinitionVisitor moduleVisitor
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.fromModuleRuleSchema


type Context
    = InDomain
    | OutsideDomain


moduleVisitor : Node Module -> Context -> ( List (Rule.Error {}), Context )
moduleVisitor node _ =
    if Module.moduleName (Node.value node) == [ "Domain" ] then
        ( exposingErrors (Module.exposingList (Node.value node)), InDomain )

    else
        ( [], OutsideDomain )


exposingErrors : Exposing.Exposing -> List (Rule.Error {})
exposingErrors exposingList =
    case exposingList of
        Exposing.All range ->
            [ Rule.error
                { message = "Keep the Level constructor private"
                , details = [ "Expose Domain.Level by name, not through exposing (..) or Level(..). Construction must stay behind the domain functions and decoder." ]
                }
                range
            ]

        Exposing.Explicit items ->
            List.filterMap
                (\node ->
                    case Node.value node of
                        Exposing.TypeExpose exposed ->
                            if exposed.name == "Level" && exposed.open /= Nothing then
                                Just
                                    (Rule.error
                                        { message = "Keep the Level constructor private"
                                        , details = [ "Expose Domain.Level by name, not through exposing (..) or Level(..). Construction must stay behind the domain functions and decoder." ]
                                        }
                                        (Node.range node)
                                    )

                            else
                                Nothing

                        _ ->
                            Nothing
                )
                items


declarationVisitor : Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor node context =
    case ( context, Node.value node ) of
        ( InDomain, Declaration.AliasDeclaration alias ) ->
            if Node.value alias.name == "Level" then
                ( [ Rule.error
                        { message = "Level must remain a custom type"
                        , details = [ "A type alias is transparent even when its name is exposed without constructors. Keep Level as an opaque custom type; its range remains a behavioral invariant checked by domain tests." ]
                        }
                        (Node.range node)
                  ]
                , context
                )

            else
                ( [], context )

        _ ->
            ( [], context )
