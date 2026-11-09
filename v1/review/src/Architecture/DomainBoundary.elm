module Architecture.DomainBoundary exposing (rule)

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.TypeAnnotation as TypeAnnotation exposing (TypeAnnotation)
import Review.ModuleNameLookupTable as Lookup exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchemaUsingContextCreator "Architecture.DomainBoundary" contextCreator
        |> Rule.withImportVisitor importVisitor
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


type Context
    = OutsideDomain
    | InDomain ModuleNameLookupTable


contextCreator : Rule.ContextCreator () Context
contextCreator =
    Rule.initContextCreator
        (\moduleName lookupTable () ->
            if moduleName == [ "Domain" ] then
                InDomain lookupTable

            else
                OutsideDomain
        )
        |> Rule.withModuleName
        |> Rule.withModuleNameLookupTable


allowedImports : List ModuleName
allowedImports =
    [ [ "Array" ]
    , [ "Basics" ]
    , [ "Bitwise" ]
    , [ "Char" ]
    , [ "Dict" ]
    , [ "List" ]
    , [ "Maybe" ]
    , [ "Result" ]
    , [ "Set" ]
    , [ "String" ]
    , [ "Tuple" ]
    , [ "Json", "Decode" ]
    , [ "Json", "Encode" ]
    ]


importVisitor : Node Import -> Context -> ( List (Rule.Error {}), Context )
importVisitor node context =
    case context of
        OutsideDomain ->
            ( [], context )

        InDomain _ ->
            let
                nameNode =
                    (Node.value node).moduleName
            in
            if List.member (Node.value nameNode) allowedImports then
                ( [], context )

            else
                ( [ Rule.error
                        { message = "Domain imports a module outside its pure boundary"
                        , details = [ "Domain may import only the approved pure core modules and Json.Decode/Json.Encode. Keep UI and effects outside Domain; review this allowlist explicitly before adding a pure helper module." ]
                        }
                        (Node.range nameNode)
                  ]
                , context
                )


forbiddenReference : ModuleNameLookupTable -> Node a -> List (Rule.Error {})
forbiddenReference lookupTable node =
    case Lookup.moduleNameFor lookupTable node of
        Just origin ->
            if List.member origin [ [ "Platform" ], [ "Platform", "Cmd" ], [ "Platform", "Sub" ] ] then
                [ Rule.error
                    { message = "Domain must not describe runtime effects"
                    , details = [ "Move Program, Cmd and Sub types and values to Main. This check resolves actual origins, including default imports, aliases and exposed names; a locally defined pure type with the same name is not an effect." ]
                    }
                    (Node.range node)
                ]

            else
                []

        Nothing ->
            []


declarationVisitor : Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor node context =
    case context of
        OutsideDomain ->
            ( [], context )

        InDomain lookupTable ->
            ( declarationAnnotations (Node.value node)
                |> List.concatMap (annotationErrors lookupTable)
            , context
            )


declarationAnnotations : Declaration -> List (Node TypeAnnotation)
declarationAnnotations declaration =
    case declaration of
        Declaration.FunctionDeclaration function ->
            functionAnnotations function

        Declaration.AliasDeclaration alias ->
            [ alias.typeAnnotation ]

        Declaration.CustomTypeDeclaration customType ->
            List.concatMap (Node.value >> .arguments) customType.constructors

        Declaration.PortDeclaration signature ->
            [ signature.typeAnnotation ]

        Declaration.Destructuring _ _ ->
            []

        Declaration.InfixDeclaration _ ->
            []


functionAnnotations : Expression.Function -> List (Node TypeAnnotation)
functionAnnotations function =
    case function.signature of
        Just signature ->
            [ (Node.value signature).typeAnnotation ]

        Nothing ->
            []


annotationErrors : ModuleNameLookupTable -> Node TypeAnnotation -> List (Rule.Error {})
annotationErrors lookupTable node =
    case Node.value node of
        TypeAnnotation.Typed name arguments ->
            forbiddenReference lookupTable name
                ++ List.concatMap (annotationErrors lookupTable) arguments

        TypeAnnotation.FunctionTypeAnnotation argument result ->
            annotationErrors lookupTable argument ++ annotationErrors lookupTable result

        TypeAnnotation.Tupled items ->
            List.concatMap (annotationErrors lookupTable) items

        TypeAnnotation.Record fields ->
            recordErrors lookupTable fields

        TypeAnnotation.GenericRecord _ fields ->
            recordErrors lookupTable (Node.value fields)

        TypeAnnotation.GenericType _ ->
            []

        TypeAnnotation.Unit ->
            []


recordErrors : ModuleNameLookupTable -> TypeAnnotation.RecordDefinition -> List (Rule.Error {})
recordErrors lookupTable fields =
    List.concatMap (Node.value >> Tuple.second >> annotationErrors lookupTable) fields


expressionVisitor : Node Expression -> Context -> ( List (Rule.Error {}), Context )
expressionVisitor node context =
    case context of
        OutsideDomain ->
            ( [], context )

        InDomain lookupTable ->
            case Node.value node of
                Expression.FunctionOrValue _ _ ->
                    ( forbiddenReference lookupTable node, context )

                Expression.LetExpression block ->
                    ( block.declarations
                        |> List.concatMap
                            (Node.value
                                >> (\declaration ->
                                        case declaration of
                                            Expression.LetFunction function ->
                                                functionAnnotations function

                                            Expression.LetDestructuring _ _ ->
                                                []
                                   )
                            )
                        |> List.concatMap (annotationErrors lookupTable)
                    , context
                    )

                _ ->
                    ( [], context )
