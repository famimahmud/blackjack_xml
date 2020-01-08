xquery version "3.0";

module namespace blackjack-controller = "blackjack-controller.xqm";
import module namespace blackjack-main = "Blackjack/Main" at "blackjack-main.xqm";

declare variable $blackjack-controller:staticPath := "../static/blackjack/";

declare
%rest:path("blackjack/setup")
%output:method("xhtml")
%updating
%rest:GET
function blackjack-controller:setup() {
    let $model := doc(concat($blackjack-controller:staticPath, "Game.xml"))
    let $redirectLink := "/blackjack/start"
    return (db:create("Game", $model), update:output(web:redirect($redirectLink)))
};

declare
%rest:GET
%output:method("html")
%rest:path("/blackjack/start")
function blackjack-controller:start(){
    let $game := blackjack-main:getGame()
        let $xslStylesheet := "GameTemplate.xsl"
        let $title := "Blackjack"
        return (blackjack-controller:genereratePage($game, $xslStylesheet, $title))
};

declare
%rest:path("/blackjack/newRound")
%rest:query-param("name", "{$name}")
%rest:query-param("id", "{$id}")
%rest:GET
%updating
function blackjack-controller:newRound($name as xs:string, $id as xs:integer){
    let $redirectLink := "/blackjack/draw"
    return (blackjack-main:newRound($name, $id), update:output(web:redirect("/blackjack/draw")))
};

declare
%rest:path("/blackjack/draw")
%output:method("html")
%rest:GET
function blackjack-controller:drawGame(){
    let $game := blackjack-main:getGame()
    let $xslStylesheet := "GameTemplate.xsl"
    let $title := "Blackjack"
    return (blackjack-controller:genereratePage($game, $xslStylesheet, $title))
};

declare function blackjack-controller:genereratePage($game as element(game), $xslStylesheet as xs:string,
        $title as xs:string) {
    let $stylesheet := doc(concat($blackjack-controller:staticPath, "xsl/", $xslStylesheet))
    let $transformed := xslt:transform($game, $stylesheet)
    return
        <html>
            <head>
                <title>{$title}</title>
            </head>
            <body style="background: url(static/blackjack/assets/TableBackground.svg">
                {$transformed}
            </body>
        </html>
};

declare
%rest:path("/blackjack/hit")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:GET
function blackjack-controller:hit($playerId as xs:integer){
    let $game := blackjack-main:getGame()
    return (
        if($game/@onTurn = $playerId)
        then (blackjack-main:drawCard($playerId),
                (: TO-DO:
                check if player is over 21 -> if true: moveTurn:)
                update:output(web:redirect("/blackjack/draw")) (:redirect always? (outside of if):)
        )
    )
};

declare
%rest:path("/blackjack/stand")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:GET
function blackjack-controller:stand($playerId as xs:integer){
    let $game := blackjack-main:getGame()
    return (
        if($game/@onTurn = $playerId)
        then (blackjack-main:moveTurn($playerId),
                update:output(web:redirect("/blackjack/draw")) (:redirect allways? (outside of if):)
        )
    )
};
