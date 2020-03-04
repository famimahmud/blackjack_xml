xquery version "3.1";

module namespace blackjack-controller = "blackjack-controller.xqm";

import module namespace request = "http://exquery.org/ns/request";
import module namespace blackjack-main = "Blackjack/Main" at "blackjack-main.xqm";
import module namespace blackjack-helper = "Blackjack/Helper" at "blackjack-helper.xqm";
import module namespace blackjack-ws = "Blackjack/WS" at "blackjack-websocket.xqm";

declare variable $blackjack-controller:staticPath := "../static/docbook_blackjack/";

declare
%rest:path("docbook_blackjack/setup")
%output:method("xhtml")
%updating
%rest:GET
function blackjack-controller:setup() {
    let $lobby_model := doc(concat($blackjack-controller:staticPath, "db/Lobby.xml"))
    let $deck_model := doc(concat($blackjack-controller:staticPath, "db/Deck.xml"))
    let $players_model := doc(concat($blackjack-controller:staticPath, "db/Players.xml"))
    let $redirectLink := "/docbook_blackjack"
    return (db:create("DocBook_Lobby", $lobby_model), db:create("DocBook_Deck", $deck_model), db:create("DocBook_Players", $players_model),
    update:output(web:redirect($redirectLink)))
};


declare
%rest:GET
%output:method("html")
%rest:query-param("playerName", "{$playerName}")
%rest:query-param("playerId", "{$playerId}")
%rest:path("/docbook_blackjack/lobby")
function blackjack-controller:start($playerName as xs:string?, $playerId as xs:string?){
        let $lobby := blackjack-main:getLobby()
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
        return blackjack-controller:generateLobby($lobby, $xslStylesheet, $parameters, $title)
};


declare
%rest:path("/docbook_blackjack/newGame")
%rest:query-param("playerName", "{$playerName}")
%rest:query-param("playerId", "{$playerId}")
%rest:query-param("singlePlayer", "{$singlePlayer}")
%rest:GET
%updating
function blackjack-controller:newGame($playerName as xs:string, $playerId as xs:string, $singlePlayer as xs:string){
        let $gameId := blackjack-helper:createGameId()
        return (blackjack-main:newGame($gameId, $playerName, $playerId, $singlePlayer),
                update:output(web:redirect(concat("/docbook_blackjack/", $gameId, "/join?playerId=", $playerId))))
};

declare
%rest:GET
%output:method("html")
%rest:path("/docbook_blackjack/{$gameId}/join")
%rest:query-param("playerId", "{$playerId}")
function blackjack-controller:join($gameId as xs:integer, $playerId as xs:string){
    let $hostname := request:hostname()
    let $port := request:port()
    let $address := concat($hostname,":",$port)
    let $websocketURL := concat("ws://",$address,"/ws/docbook_blackjack")
    let $getURL := concat("http://", $address, "/docbook_blackjack/", $gameId, "/getGameLayout?playerId=", $playerId)
    let $subscription := concat("/docbook_blackjack/", $gameId ,"/", $playerId)
    let $html :=
        <html>
            <head>
                <title>Blackjack</title>
                <script src="/static/docbook_blackjack/JS/jquery-3.2.1.min.js"></script>
                <script src="/static/docbook_blackjack/JS/stomp.js"></script>
                <script src="/static/docbook_blackjack/JS/ws-element.js"></script>
                <link rel="icon" type="image/svg+xml" href="/static/docbook_blackjack/assets/icons/Logo.svg" sizes="any"/>
                <link rel="stylesheet" type="text/css" href="/static/docbook_blackjack/css/gameStyle.css"/>
            </head>
            <body style="background: url(/static/docbook_blackjack/assets/TableBackgroundCompressed.svg">
                <ws-stream id = "Blackjack" url="{$websocketURL}" subscription = "{$subscription}" geturl = "{$getURL}"/>
            </body>
        </html>
    return $html
};

declare
%rest:path("/docbook_blackjack/{$gameId}/newRound")
%rest:GET
%updating
function blackjack-controller:newRound($gameId as xs:integer){
    blackjack-main:newRound($gameId),
    update:output(web:redirect(concat("/docbook_blackjack/", $gameId, "/pay")))
};


declare
%rest:path("/docbook_blackjack")
%rest:GET
%updating
function blackjack-controller:redirectLobby(){
    update:output(web:redirect("/docbook_blackjack/lobby"))
};

declare function blackjack-controller:generateLobby($lobby as element(lobby), $xslStylesheet as xs:string, $parameters as item()*,
        $title as xs:string) {
    let $stylesheet := doc(concat($blackjack-controller:staticPath, "xsl/", $xslStylesheet))
    let $transformed := xslt:transform($lobby, $stylesheet, $parameters)
    return
        <html>
            <head>
                <title>{$title}</title>
                <link rel="icon" type="image/svg+xml" href="/static/docbook_blackjack/assets/icons/Logo.svg" sizes="any"/>
                <link rel="stylesheet" type="text/css" href="/static/docbook_blackjack/css/lobbyStyle.css"/>
            </head>
            <body style="background: url(/static/docbook_blackjack/assets/LobbyBackground.svg">
                {$transformed}
            </body>
        </html>
};

declare
%rest:path("/docbook_blackjack/{$gameId}")
%rest:GET
function blackjack-controller:drawGame($gameId as xs:integer) {
    let $game := blackjack-main:getGame($gameId)
    let $xslStylesheet := "GameTemplate.xsl"
    let $title := "Blackjack"
    return (
        let $stylesheet := doc(concat($blackjack-controller:staticPath, "xsl/GameTemplate.xsl"))
        let $wsIds := blackjack-ws:getIDs()
        return (
            for $wsId in $wsIds
                where (blackjack-ws:get($wsId, "applicationId") = "Blackjack" and blackjack-ws:get($wsId, "gameId") = $gameId)
                    let $playerId := blackjack-ws:get($wsId, "playerId")
                    let $destinationPath := concat("/docbook_blackjack/", $gameId ,"/", $playerId)
                    let $transformed := blackjack-controller:getGameLayout($gameId, $playerId)
                    return (blackjack-ws:send($transformed, $destinationPath)))
    )
};

declare
%rest:path("/docbook_blackjack/{$gameId}/getGameLayout")
%rest:query-param("playerId", "{$playerId}")
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
                <link rel="icon" type="image/svg+xml" href="/static/docbook_blackjack/assets/icons/Logo.svg" sizes="any"/>
                <link rel="stylesheet" type="text/css" href="/static/docbook_blackjack/css/gameStyle.css"/>
            </head>
            <body style="background: url(/static/docbook_blackjack/assets/TableBackgroundCompressed.svg">
                {$transformed}
            </body>
        </html>
};


declare
%rest:path("/docbook_blackjack/{$gameId}/bet")
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
        update:output(web:redirect(concat("/docbook_blackjack/", $gameId)))
    )
};


declare
%rest:path("/docbook_blackjack/{$gameId}/confirmBet")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:confirmBet($gameId as xs:integer, $playerId as xs:string){
    let $game := blackjack-main:getGame($gameId)
    return (
        if($game/@phase = "bet")
        then blackjack-main:confirmBet($gameId, $playerId),
        update:output(web:redirect(concat("/docbook_blackjack/", $gameId)))
    )
};


declare
%rest:path("/docbook_blackjack/{$gameId}/resetBet")
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
        update:output(web:redirect(concat("/docbook_blackjack/", $gameId)))
    )
};


declare
%rest:path("/docbook_blackjack/{$gameId}/dealPhase")
%output:method("html")
%rest:GET
%updating
function blackjack-controller:dealPhase($gameId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        if($game/@phase = "deal")
        then blackjack-main:dealPhase($gameId)
        )
};


declare
%rest:path("/docbook_blackjack/{$gameId}/handOutOneCardToEach")
%output:method("html")
%rest:GET
%updating
function blackjack-controller:handOutOneCardToEach($gameId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        if($game/@phase = "deal")
        then (blackjack-main:handOutOneCardToEach($gameId),
            blackjack-main:moveTurn($gameId, "dealer"),
            replace value of node $blackjack-main:lobby/game[@id = $gameId]/@phase with "play")
        ),
        if(exists($blackjack-main:lobby/game[@id = $gameId]/players/player/left) ) then (
            let $parameters := map {
                        "playerName": $blackjack-main:lobby/game[@id = $gameId]/players/player[exists(left)]/@name,
                        "playerId": $blackjack-main:lobby/game[@id = $gameId]/players/player[exists(left)]/@id
                    }
                    return update:output(web:redirect("/docbook_blackjack/lobby", $parameters)))
            else update:output(web:redirect(concat("/docbook_blackjack/", $gameId)))
};


declare
%rest:path("/docbook_blackjack/{$gameId}/hit")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:hit($gameId as xs:integer, $playerId as xs:string){
    let $game := blackjack-main:getGame($gameId)
    return (
        (if($game/@onTurn = $playerId and $game/@phase = "play" and $game/players/player[@id=$playerId]/hand/@sum < 22)
        then blackjack-main:drawCard($gameId, $playerId)),
        update:output(web:redirect(concat("/docbook_blackjack/", $gameId)))
    )
};


declare
%rest:path("/docbook_blackjack/{$gameId}/stand")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:stand($gameId as xs:integer, $playerId as xs:string){
    let $game := blackjack-main:getGame($gameId)
    return (
        if($game/@onTurn = $playerId and $game/@phase = "play")
        then (blackjack-main:moveTurn($gameId, $playerId)
        ),
        update:output(web:redirect(concat("/docbook_blackjack/", $gameId)))
    )
};

declare
%rest:path("/docbook_blackjack/{$gameId}/exit")
%rest:query-param("playerId", "{$playerId}")
%rest:query-param("playerName", "{$playerName}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:exit($gameId as xs:integer, $playerId as xs:string, $playerName as xs:string){
    let $game := blackjack-main:getGame($gameId)
    let $parameters := map {
            "playerName": $playerName,
            "playerId": $playerId
        }
    return (
        if (exists($game/players/player[@id=$playerId])) then (
        insert node <left/> into $game/players/player[@id=$playerId],
        if(exists($game[@id=$gameId]/players/player[@id=$playerId])) (:Check if the player is in the Game:)
        then(if(count($game[@id=$gameId]/players/player) = 1)
            then (blackjack-main:endGame($gameId))
            else (blackjack-main:leaveGame($gameId, $playerId)))
        ),
        update:output(web:redirect("/docbook_blackjack/lobby", $parameters))
    )
};


declare
%rest:path("/docbook_blackjack/{$gameId}/dealerTurn")
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
%rest:path("/docbook_blackjack/{$gameId}/pay")
%output:method("html")
%rest:GET
%updating
function blackjack-controller:pay($gameId as xs:integer){
    let $game := blackjack-main:getGame($gameId)
    return (
        (if ($game/@phase = "pay")
            then blackjack-main:payPlayers($gameId)),
                update:output(web:redirect(concat("/docbook_blackjack/", $gameId)))
    )
};

declare
%rest:path("/docbook_blackjack/restoreAccount")
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
%rest:path("/docbook_blackjack/createAccount")
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
        update:output(web:redirect("/docbook_blackjack/lobby", $parameters))
    )
};

declare
%rest:path("/docbook_blackjack/{$gameId}/joinGame")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:joinGame($gameId as xs:integer, $playerId as xs:string){
        blackjack-main:addPlayer($gameId, $playerId)
};
