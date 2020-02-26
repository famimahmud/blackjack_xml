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
    let $game_model := doc(concat($blackjack-controller:staticPath, "Game.xml"))
    let $lobby_model := doc(concat($blackjack-controller:staticPath, "Lobby.xml"))
    let $deck_model := doc(concat($blackjack-controller:staticPath, "Deck.xml"))
    let $players_model := doc(concat($blackjack-controller:staticPath, "Players.xml"))
    let $redirectLink := "/blackjack/start"
    return (db:create("Game", $game_model), db:create("Lobby", $lobby_model), db:create("Deck", $deck_model), db:create("Players", $players_model), update:output(web:redirect($redirectLink)))
};

declare
%rest:GET
%output:method("html")
%rest:path("/blackjack/start")
function blackjack-controller:start(){
    let $lobby := blackjack-main:getLobby()
        let $xslStylesheet := "LobbyTemplate.xsl"
        let $title := "Blackjack Lobby"
        return (blackjack-controller:genererateLobby($lobby, $xslStylesheet, $title))
};

declare
%rest:path("/blackjack/newGame")
%rest:query-param("name", "{$name}")
%rest:query-param("id", "{$id}")
%rest:GET
%updating
function blackjack-controller:newGame($name as xs:string, $id as xs:integer){
    let $redirectLink := "/blackjack/draw"
    return (blackjack-main:newGame($name, $id), update:output(web:redirect("/blackjack/draw")))
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

declare function blackjack-controller:genererateLobby($lobby as element(lobby), $xslStylesheet as xs:string,
        $title as xs:string) {
    let $stylesheet := doc(concat($blackjack-controller:staticPath, "xsl/", $xslStylesheet))
    let $transformed := xslt:transform($lobby, $stylesheet)
    return
        <html>
            <head>
                <title>{$title}</title>
            </head>
            <body style="background: url(/static/blackjack/assets/LobbyBackground.svg">
                {$transformed}
            </body>
        </html>
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
            <body style="background: url(/static/blackjack/assets/TableBackground.svg">
                {$transformed}
            </body>
        </html>
};

declare
%rest:path("/blackjack/bet")
%rest:query-param("value", "{$chipValue}")
%rest:query-param("playerID", "{$playerID}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:bet($playerID as xs:string, $chipValue as xs:integer){
    let $game := blackjack-main:getGame()
    return (
        if($game/@phase = "bet" and $game/players/player[@id = $playerID]/pool/@locked = "false")
        then (  blackjack-main:bet($playerID, $chipValue),
            update:output(web:redirect("/blackjack/draw"))
        )
    )
};

declare
%rest:path("/blackjack/confirmBet")
%rest:query-param("playerID", "{$playerID}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:confirmBet($playerID as xs:string){
    let $game := blackjack-main:getGame()
    return (
        if($game/@phase = "bet")
        then (replace node $game/players/player[@id = $playerID]/pool/@locked with "true",
             (:check if player is over 21 -> if true: moveTurn:)
            (if (count(game/players/player/pool[@locked="true"]/@locked) = count(game/players/player))
                then blackjack-main:handOutCards()),
                update:output(web:redirect("/blackjack/draw")) (:redirect always? (outside of if):)
        )
    )
};

declare
%rest:path("/blackjack/resetBet")
%rest:query-param("playerID", "{$playerID}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:resetBet($playerID as xs:string){
    let $game := blackjack-main:getGame()
    let $wallet := xs:integer($game/players/player[@id=$playerID]/wallet/node())
    let $poolBet := sum($game/players/player[@id=$playerID]/pool/chip/value)
    return (
        if($game/@phase = "bet" and $game/players/player[@id = $playerID]/pool/@locked = "false")
        then (  replace node $game/players/player[@id=$playerID]/wallet/node() with ($wallet + $poolBet),
                replace node $game/players/player[@id = $playerID]/pool with <pool locked="false"></pool>,
                update:output(web:redirect("/blackjack/draw"))
        )
    )
};

declare
%rest:path("/blackjack/hit")
%rest:query-param("playerID", "{$playerID}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:hit($playerID as xs:string){
    let $game := blackjack-main:getGame()
    return (
        (if($game/@onTurn = $playerID and $game/@phase = "play" and blackjack-main:calculateHandValue($playerID) < 21)
        then blackjack-main:drawCard($playerID)),
        update:output(web:redirect("/blackjack/draw"))
    )
};

declare
%rest:path("/blackjack/stand")
%rest:query-param("playerID", "{$playerID}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:stand($playerID as xs:string){
    let $game := blackjack-main:getGame()
    return (
        if($game/@onTurn = $playerID and $game/@phase = "play")
        then (blackjack-main:moveTurn($playerID),
                update:output(web:redirect("/blackjack/draw")) (:redirect allways? (outside of if):)
        )
    )
};
