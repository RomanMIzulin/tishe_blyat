module Architecture.PortsOnlyInMain exposing (rule)

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchema "Architecture.PortsOnlyInMain" OutsideMain
        |> Rule.withModuleDefinitionVisitor moduleVisitor
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.fromModuleRuleSchema


type Context
    = InMain
    | OutsideMain


moduleVisitor : Node Module -> Context -> ( List (Rule.Error {}), Context )
moduleVisitor node _ =
    if Module.moduleName (Node.value node) == [ "Main" ] then
        ( [], InMain )

    else if Module.isPortModule (Node.value node) then
        ( [ violation node ], OutsideMain )

    else
        ( [], OutsideMain )


declarationVisitor : Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor node context =
    case ( context, Node.value node ) of
        ( OutsideMain, Declaration.PortDeclaration _ ) ->
            ( [ violation node ], context )

        _ ->
            ( [], context )


violation : Node a -> Rule.Error {}
violation node =
    Rule.error
        { message = "Ports belong only in Main"
        , details = [ "Keep the browser IO contract in Main and implement it in bridge.js. Do not create another port module or declare ports in a domain or UI helper." ]
        }
        (Node.range node)
