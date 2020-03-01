xquery version "3.1";

module namespace blackjack-controller = "blackjack-controller.xqm";
import module namespace blackjack-main = "Blackjack/Main" at "blackjack-main.xqm";
import module namespace blackjack-helper = "Blackjack/Helper" at "blackjack-helper.xqm";

declare variable $blackjack-controller:staticPath := "../static/blackjack/";

declare
%rest:path("blackjack/setup")
%output:method("xhtml")
%updating
%rest:GET
function blackjack-controller:setup() {
    let $games_model := doc(concat($blackjack-controller:staticPath, "Games.xml"))
    let $deck_model := doc(concat($blackjack-controller:staticPath, "Deck.xml"))
    let $players_model := doc(concat($blackjack-controller:staticPath, "Players.xml"))
    let $highscores_model := doc(concat($blackjack-controller:staticPath, "Highscores.xml"))
    let $redirectLink := "/blackjack"
    return (db:create("Games", $games_model), db:create("Deck", $deck_model), db:create("Players", $players_model), db:create("Highscores", $highscores_model), update:output(web:redirect($redirectLink)))
};

(:
declare
%rest:GET
%output:method("html")
%rest:path("/blackjack")
function blackjack-controller:start(){
        let $xslStylesheet := "LobbyTemplate.xsl"
        let $title := "Blackjack | Lobby"
        return (blackjack-controller:generateLobby($lobby, $xslStylesheet, $title))
};
:)

declare
%rest:path("/blackjack/newGame")
%rest:query-param("playerName", "{$playerName}")
%rest:query-param("playerId", "{$playerId}")
%rest:GET
%updating
function blackjack-controller:newGame($playerName as xs:string, $playerId as xs:integer){
        let $gameId := blackjack-helper:createGameId()
        return (blackjack-main:newGame($gameId, $playerName, $playerId),
        update:output(web:redirect(concat("/blackjack/", $gameId))))
};


declare
%rest:path("/blackjack/{$gameId}/newRound")
%rest:GET
%updating
function blackjack-controller:newRound($gameId as xs:integer){
    blackjack-main:newRound(),
    update:output(web:redirect(concat("/blackjack/", $gameId)))
};


declare
%rest:path("/blackjack/{$gameId}")
%output:method("html")
%rest:GET
function blackjack-controller:drawGame($gameId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    let $xslStylesheet := "GameTemplate.xsl"
    let $title := "Blackjack"
    return (blackjack-controller:generatePage($game, $xslStylesheet, $title))
};


declare function blackjack-controller:generateLobby($lobby as element(lobby), $xslStylesheet as xs:string,
        $title as xs:string) {
    let $stylesheet := doc(concat($blackjack-controller:staticPath, "xsl/", $xslStylesheet))
    let $transformed := xslt:transform($lobby, $stylesheet)
    return
        <html>
            <head>
                <title>{$title}</title>
                <link rel="icon" type="image/svg+xml" href="/static/blackjack/assets/icons/Logo.svg" sizes="any"/>
            </head>
            <body style="background: url(/static/blackjack/assets/LobbyBackground.svg">
                {$transformed}
            </body>
        </html>
};


declare function blackjack-controller:generatePage($game as element(game), $xslStylesheet as xs:string,
        $title as xs:string) {
    let $stylesheet := doc(concat($blackjack-controller:staticPath, "xsl/", $xslStylesheet))
    let $transformed := xslt:transform($game, $stylesheet)
    return
        <html>
            <head>
                <title>{$title}</title>
                <link rel="icon" type="image/svg+xml" href="/static/blackjack/assets/icons/Logo.svg" sizes="any"/>
            </head>
            <body style="background: url(/static/blackjack/assets/TableBackground.svg">
                {$transformed}
            </body>
        </html>
};


declare
%rest:path("/blackjack/{$gameId}/bet")
%rest:query-param("value", "{$chipValue}")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:bet($gameId as xs:integer, $playerId as xs:integer, $chipValue as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        (if($game/@phase = "bet" and $game/players/player[@id = $playerId]/pool/@locked = "false")
        then blackjack-main:bet($playerId, $chipValue)),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
    )
};


declare
%rest:path("/blackjack/{$gameId}/confirmBet")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:confirmBet($gameId as xs:integer, $playerId as xs:string){
    let $game := blackjack-main:getGame($gameId)
    return (
        if($game/@phase = "bet")
        then blackjack-main:confirmBet($playerId),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
    )
};


declare
%rest:path("/blackjack/{$gameId}/resetBet")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:resetBet($gameId as xs:integer, $playerId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    let $wallet := xs:integer($game/players/player[@id=$playerId]/wallet/node())
    let $poolBet := sum($game/players/player[@id=$playerId]/pool/chip/value)
    return (
        if($game/@phase = "bet" and $game/players/player[@id = $playerId]/pool/@locked = "false")
        then (  replace node $game/players/player[@id=$playerId]/wallet/node() with ($wallet + $poolBet),
                replace node $game/players/player[@id = $playerId]/pool with <pool locked="false"></pool>
        ),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
    )
};


declare
%rest:path("/blackjack/{$gameId}/dealPhase")
%output:method("html")
%rest:GET
%updating
function blackjack-controller:dealPhase($gameId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        if($game/@phase = "deal")
        then (blackjack-main:dealPhase())
        )
};


declare
%rest:path("/blackjack/{$gameId}/handOutOneCardToEach")
%output:method("html")
%rest:GET
%updating
function blackjack-controller:handOutOneCardToEach($gameId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        if($game/@phase = "deal")
        then (blackjack-main:handOutOneCardToEach(),
            blackjack-main:moveTurn("dealer"),
            replace value of node $blackjack-main:game/@phase with "play")
        ),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
};


declare
%rest:path("/blackjack/{$gameId}/hit")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:hit($gameId as xs:integer, $playerId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        (if($game/@onTurn = $playerId and $game/@phase = "play" and $game/players/player[@id=$playerId]/hand/@sum < 21)
        then blackjack-main:drawCard($playerId)),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
    )
};


declare
%rest:path("/blackjack/{$gameId}/stand")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:stand($gameId as xs:integer, $playerId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        if($game/@onTurn = $playerId and $game/@phase = "play")
        then (blackjack-main:moveTurn($playerId) (:redirect allways? (outside of if):)
        ),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
    )
};


declare
%rest:path("/blackjack/{$gameId}/dealerTurn")
%output:method("html")
%rest:GET
%updating
function blackjack-controller:dealerTurn($gameId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        if($game/@onTurn = "dealer" and $game/@phase = "play")
        then (blackjack-main:dealerTurn())
        )
};


declare
%rest:path("/blackjack/{$gameId}/pay")
%output:method("html")
%rest:GET
%updating
function blackjack-controller:pay($gameId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        (if ($game/@phase = "pay")
            then blackjack-main:payPhase()),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
    )
};


(:
declare
%rest:path("/blackjack/restoreAccount")
%rest:query-param("playerName", "{$playerName}")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:restoreAccount($playerName as xs:string, $playerId as xs:string){
    let $player := blackjack-main:getPlayers()/player[@id=$playerId and @name=$playerName]
    let $lobby := blackjack-main:getLobby()
    return (
        if(count($lobby/player) = 0)
        then (insert node $player into $lobby)
        else (replace node $lobby/player with $player),
        update:output(web:redirect("/blackjack"))
    )
};
:)

declare
%rest:path("/blackjack/createAccount")
%rest:query-param("playerName", "{$playerName}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:createAccount($playerName as xs:string){
    let $players:= blackjack-main:getPlayers()
    let $newID := blackjack-helper:createPlayerId()
    let $newPlayer := <player id="{$newID}" name="{$playerName}" highscore="0"/>
    return (
        insert node $newPlayer into $players,
        update:output(web:redirect("/blackjack")))
};
