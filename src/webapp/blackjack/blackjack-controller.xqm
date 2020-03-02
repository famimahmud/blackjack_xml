xquery version "3.1";

module namespace blackjack-controller = "blackjack-controller.xqm";

import module namespace request = "http://exquery.org/ns/request";
import module namespace blackjack-main = "Blackjack/Main" at "blackjack-main.xqm";
import module namespace blackjack-helper = "Blackjack/Helper" at "blackjack-helper.xqm";
import module namespace blackjack-ws = "Blackjack/WS" at "blackjack-websocket.xqm";

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
    return (db:create("Games", $games_model), db:create("Deck", $deck_model), db:create("Players", $players_model), db:create("Highscores", $highscores_model),
    update:output(web:redirect($redirectLink)))
};


declare
%rest:GET
%output:method("html")
%rest:query-param("playerName", "{$playerName}")
%rest:query-param("playerId", "{$playerId}")
%rest:path("/blackjack/lobby")
function blackjack-controller:start($playerName as xs:string?, $playerId as xs:string?){
        let $games := blackjack-main:getGames()
        let $xslStylesheet := "LobbyTemplate.xsl"
        let $title := "Blackjack | Lobby"
        let $emptyMap := map {
                                    "isLoggedIn": 0,
                                    "playerName": '',
                                    "playerId": '',
                                    "playerHighscore": ''
                             }
        let $parameters := if (blackjack-helper:playerExists($playerName, $playerId)) then (
            map {
                        "isLoggedIn": 1,
                        "playerName": $playerName,
                        "playerId": $playerId,
                        "playerHighscore": blackjack-helper:getPlayerHighscore($playerName, $playerId)
                }
        ) else (
            $emptyMap
        )
        return (blackjack-controller:generateLobby($games, $xslStylesheet, $parameters, $title))
};


declare
%rest:path("/blackjack/newGame")
%rest:query-param("playerName", "{$playerName}")
%rest:query-param("playerId", "{$playerId}")
%rest:query-param("singlePlayer", "{$singlePlayer}")
%rest:GET
%updating
function blackjack-controller:newGame($playerName as xs:string, $playerId as xs:string, $singlePlayer as xs:string){
        let $gameId := blackjack-helper:createGameId()
        return (blackjack-main:newGame($gameId, $playerName, $playerId, $singlePlayer),
            (if ($singlePlayer = "false")
            then update:output(web:redirect(concat("/blackjack/", $gameId, "/join/", $playerId)))
            else update:output(web:redirect(concat("/blackjack/", $gameId)))))
};

declare
%rest:GET
%output:method("html")
%rest:path("/blackjack/{$gameId}/join/{$playerID}")
function blackjack-controller:join($gameId as xs:string, $playerID as xs:string){
    let $hostname := request:hostname()
    let $port := request:port()
    let $address := concat($hostname,":",$port)
    let $websocketURL := concat("ws://",$address,"/ws/blackjack")
    let $getURL := concat("http://", $address, "/blackjack/", $gameId, "/getGameLayout/", $playerID)
    let $subscription := concat("/blackjack/", $gameId ,"/", $playerID)
    let $html :=
        <html>
            <head>
                <title>Blackjack</title>
                <script src="/static/blackjack/JS/jquery-3.2.1.min.js"></script>
                <script src="/static/blackjack/JS/stomp.js"></script>
                <script src="/static/blackjack/JS/ws-element.js"></script>
                <link rel="icon" type="image/svg+xml" href="/static/blackjack/assets/icons/Logo.svg" sizes="any"/>
            </head>
            <body style="background: url(/static/blackjack/assets/TableBackgroundCompressed.svg">
                <ws-stream id = "Blackjack" url="{$websocketURL}" subscription = "{$subscription}" geturl = "{$getURL}"/>
            </body>
        </html>
    return $html
};

declare
%rest:path("/blackjack/{$gameId}/newRound")
%rest:GET
%updating
function blackjack-controller:newRound($gameId as xs:integer){
    blackjack-main:newRound($gameId),
    update:output(web:redirect(concat("/blackjack/", $gameId)))
};


declare
%rest:path("/blackjack")
%rest:GET
%updating
function blackjack-controller:redirectLobby(){
    update:output(web:redirect("/blackjack/lobby"))
};

declare function blackjack-controller:generateLobby($games as element(games), $xslStylesheet as xs:string, $parameters as item()*,
        $title as xs:string) {
    let $stylesheet := doc(concat($blackjack-controller:staticPath, "xsl/", $xslStylesheet))
    let $transformed := xslt:transform($games, $stylesheet, $parameters)
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

declare
%rest:path("/blackjack/{$gameId}")
%rest:GET
function blackjack-controller:drawGame($gameId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    let $xslStylesheet := "GameTemplate.xsl"
    let $title := "Blackjack"
    return (if ($game/@singlePlayer = "true") then
            blackjack-controller:generatePage($gameId, $game/players/player[position() = 1]/@id, $title)
        else    (: send via Websocket if the game is Multiclient:)
                let $stylesheet := doc(concat($blackjack-controller:staticPath, "xsl/GameTemplate.xsl"))
                let $wsIds := blackjack-ws:getIDs()
                return
                    (for $wsId in $wsIds
                        where (blackjack-ws:get($wsId, "applicationID") = "Blackjack" and blackjack-ws:get($wsId, "gameID") = $gameId)
                        let $playerId := blackjack-ws:get($wsId, "playerID")
                        let $destinationPath := concat("/blackjack/", $gameId ,"/", $playerId)
                        let $transformed := blackjack-controller:getGameLayout($gameId, $playerId)
                        return (blackjack-ws:send($transformed, $destinationPath)))
    )
};

declare
%rest:path("/blackjack/{$gameId}/getGameLayout/{$playerId}")
%output:method("html")
%rest:GET
function blackjack-controller:getGameLayout($gameId as xs:integer, $playerId as xs:integer){
    let $stylesheet := doc(concat($blackjack-controller:staticPath, "xsl/GameTemplate.xsl"))
    let $parameters := map {
        "gameId": $gameId,
        "playerId": $playerId
    }
    let $game := blackjack-main:getGame($gameId)
    let $transformed := xslt:transform($game, $stylesheet, $parameters)
    return ($transformed)
};

declare function blackjack-controller:generatePage($gameId as xs:integer, $playerId as xs:integer, $title as xs:string) {
    let $transformed := blackjack-controller:getGameLayout($gameId, $playerId)
    return
        <html>
            <head>
                <title>{$title}</title>
                <link rel="icon" type="image/svg+xml" href="/static/blackjack/assets/icons/Logo.svg" sizes="any"/>
            </head>
            <body style="background: url(/static/blackjack/assets/TableBackgroundCompressed.svg">
                {$transformed}
            </body>
        </html>
};


declare
%rest:path("/blackjack/{$gameId}/bet")
%rest:query-param("playerId", "{$playerId}")
%rest:query-param("chipValue", "{$chipValue}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:bet($gameId as xs:integer, $playerId as xs:string, $chipValue as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        (if($game/@phase = "bet" and $game/players/player[@id = $playerId]/pool/@locked = "false")
        then blackjack-main:bet($gameId, $playerId, $chipValue)),
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
        then blackjack-main:confirmBet($gameId, $playerId),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
    )
};


declare
%rest:path("/blackjack/{$gameId}/resetBet")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:resetBet($gameId as xs:integer, $playerId as xs:string){
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
        then (blackjack-main:dealPhase($gameId))
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
        then (blackjack-main:handOutOneCardToEach($gameId),
            blackjack-main:moveTurn($gameId, "dealer"),
            replace value of node $blackjack-main:games/game[@id = $gameId]/@phase with "play")
        ),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
};


declare
%rest:path("/blackjack/{$gameId}/hit")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:hit($gameId as xs:integer, $playerId as xs:string){
    let $game := blackjack-main:getGame($gameId)
    return (
        (if($game/@onTurn = $playerId and $game/@phase = "play" and $game/players/player[@id=$playerId]/hand/@sum < 22)
        then blackjack-main:drawCard($gameId, $playerId)),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
    )
};


declare
%rest:path("/blackjack/{$gameId}/stand")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:stand($gameId as xs:integer, $playerId as xs:string){
    let $game := blackjack-main:getGame($gameId)
    return (
        if($game/@onTurn = $playerId and $game/@phase = "play")
        then (blackjack-main:moveTurn($gameId, $playerId) (:redirect allways? (outside of if):)
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
        then (blackjack-main:dealerTurn($gameId))
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
            then blackjack-main:payPlayers($gameId)),
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
%rest:path("/blackjack/restoreAccount")
%rest:query-param("playerName", "{$playerName}")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:GET
function blackjack-controller:restoreAccount($playerName as xs:string, $playerId as xs:string){
    let $playerExists := blackjack-helper:playerExists($playerName, $playerId)
    return if ($playerExists) then (
        blackjack-controller:start($playerName, $playerId)
    )
};


declare
%rest:path("/blackjack/createAccount")
%rest:query-param("playerName", "{$playerName}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:createAccount($playerName as xs:string){
    let $players:= blackjack-main:getPlayers()
    let $playerId := string(blackjack-helper:createPlayerId())
    let $newPlayer := <player id="{$playerId}" name="{$playerName}" highscore="0"/>
    let $parameters := map {
        "playerName": $playerName,
        "playerId": $playerId
    }
    return (
        insert node $newPlayer into $players,
        update:output(web:redirect("/blackjack/lobby", $parameters))
    )
};
