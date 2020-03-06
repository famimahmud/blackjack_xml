xquery version "3.1";
(:~
 : Module Name: Blackjack Controller
 : "The controller is responsible for all HTTP request and interacts directly with the client.
 : It abstracts the interface from the client and calls the responsible methods in the main
 : game module for the Blackjack game. It furthermore handles redirects, creation of the
 : database, and generation of the XSLT delivered to the clients view for display." (Philipp Ulrich)
 :
 : @author   Moritz Issig, Patryk Brzoza, Fami Mahmud
 : @see      e.g. chapter controller in the documentation
 : @version  1.0
 :)
module namespace blackjack-controller = "blackjack-controller.xqm";

import module namespace request = "http://exquery.org/ns/request";
import module namespace blackjack-main = "Blackjack/Main" at "blackjack-main.xqm";
import module namespace blackjack-helper = "Blackjack/Helper" at "blackjack-helper.xqm";
import module namespace blackjack-ws = "Blackjack/WS" at "blackjack-websocket.xqm";

declare variable $blackjack-controller:staticPath := "../static/docbook_blackjack/";

 (:~
  : if the datacase doesn't exist -> create the databases "Lobby", "Deck"
  : @return redirects User to the Lobby
  :)
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
    return (
        if (not(db:exists("DocBook_Lobby")))
        then (db:create("DocBook_Lobby", $lobby_model), db:create("DocBook_Deck", $deck_model), db:create("DocBook_Players", $players_model)),
    update:output(web:redirect($redirectLink)))
};

 (:~
  : return the Lobby-Page to the user
  : if given playerName and playerId exist -> loggedIn-Lobby
  : else: loggedOut-Lobby
  : @playerName name of the logged in user
  : @playerId id of the logged in user
  : @return created Lobby-File
  :)
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

 (:~
  : creates a new game with the given player as first player
  : @playerName name of user, who created the new game
  : @playerId id of user, who created the new game
  : @singlePlayer flag, which is set if the new game is a singlePlayer game
  : @return model change with new game and redirects user to new game-page
  :)
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

 (:~
  : join an existing MultiPlayer-Game -> subscribe to Websocket on that page
  : @gameId Id of the game, which the players joins
  : @playerId id of the user, who joins the game
  : @return redirects user to game-page
  :)
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

 (:~
  : redirects user to Lobby
  :)
declare
%rest:path("/docbook_blackjack")
%rest:GET
%updating
function blackjack-controller:redirectLobby(){
    update:output(web:redirect("/docbook_blackjack/lobby"))
};

 (:~
  : gives the HTML-View of the Lobby
  : @lobby Lobby-Element, which should be generated
  : @xslStylesheet name of the used xsl-Stylesheet
  : @parameters parameters, which are used in the xsl-Stylesheet
  : @return HTML-Text with the generated Lobby-View
  :)
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

 (:~
  : update game-views via websocket
  : @gameId Id of the game, were all players get a websocket update
  : @return empty HTML (for hiddenFrame)
  :)
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

 (:~
  : returns the HTML of the game
  : @gameId Id of the game, which will be generated
  : @playerId Id of the player, for whom the game is generated
  : @return HTML of the game with specific player-View
  :)
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

 (:~
  : place an chip into the player-pool
  : @gameId Id of the game, where the player bets
  : @playerId Id of the player, who bets
  : @chipValue value of the bet chip
  : @return model change and via websocket updated page
  :)
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

 (:~
  : confirms bet chips of the given player
  : @gameId Id of the game, where the player confirms his bet
  : @playerId Id of the player, who confirms his bet
  : @return via websocket updated page
  :)
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

 (:~
  : reset bet chips of the given player
  : @gameId Id of the game, where the player resets his bet
  : @playerId Id of the player, who resets his bet
  : @return model change and via websocket updated page
  :)
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

 (:~
  : dealer gives two card to each
  : @gameId Id of the game, where the dealer deals the cards
  : @return model change
  :)
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

 (:~
  : dealer gives one card to each
  : @gameId Id of the game, where the dealer deals the cards
  : @return model change and via websocket updated page
  :         or if a leaving players triggered the dealPhase -> return this player to the Lobby
  :)
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

 (:~
  : player hits (gets one card)
  : @gameId Id of the game, where the player hits
  : @playerId Id of the hitting player
  : @return model change and via websocket updated page
  :)
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

 (:~
  : player stands (stops to get more cards)
  : @gameId Id of the game, where the player stands
  : @playerId Id of the stand player
  : @return model change and via websocket updated page
  :)
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

 (:~
  : player exits the game:
  :     if spectator -> direct to Lobby
  :     if only player in game -> delete game and go to Lobby
  :     if not last player in game -> mark player as left and go to Lobby
                eventually trigger dealerPhase or dealerTurn
  : @gameId Id of the game, where the player exits
  : @playerId Id of the exiting player
  : @return model change no update via websocket
  :)
declare
%rest:path("/docbook_blackjack/{$gameId}/exit")
%rest:query-param("playerId", "{$playerId}")
%rest:query-param("playerName", "{$playerName}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:exit($gameId as xs:integer, $playerId as xs:string, $playerName as xs:string){
    let $game := blackjack-main:getGame($gameId)
    return (
        if (exists($game/players/player[@id=$playerId])) then (
        insert node <left/> into $game/players/player[@id=$playerId],
        if(exists($game[@id=$gameId]/players/player[@id=$playerId])) (:Check if the player is in the Game:)
        then(if(count($game[@id=$gameId]/players/player) = 1)
            then (blackjack-main:endGame($gameId))
            else (blackjack-main:leaveGame($gameId, $playerId))),
            update:output(web:redirect("/docbook_blackjack/lobby", map {"playerName": $playerName,"playerId": $playerId}))
        ) else (
        update:output(web:redirect("/docbook_blackjack/lobby", map {"playerName": blackjack-helper:getPlayerName($playerId), "playerId": $playerId}))
        )
    )
};

 (:~
  : dealer starts his turn
  : @gameId Id of the game, where the dealerTurn starts
  : @return model change and update via websocket
  :)
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

 (:~
  : pay ot every player and remove chips and cards from table
  : @gameId Id of the game, where the pay out starts
  : @return model change and update via websocket
  :)
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

 (:~
  : log in with an existing player
  : @playerName name of the existing player
  : @playerId Id of the existing player
  : @return if player really exists: model change and lobby-page-update
  :)
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

 (:~
  : log in as a new player
  : @playerName name for the new player
  : @return model change and lobby-page-update
  :)
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

 (:~
  : add player to game and join Game
  : @gameId id for the game, where the player joins
  : @playerId id for the joining player
  : @return model change and redirect to game-Page
  :)
declare
%rest:path("/docbook_blackjack/{$gameId}/joinGame")
%rest:query-param("playerId", "{$playerId}")
%output:method("html")
%rest:POST
%updating
function blackjack-controller:joinGame($gameId as xs:integer, $playerId as xs:string){
        blackjack-main:addPlayer($gameId, $playerId)
};
