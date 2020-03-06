xquery version "3.0";

module namespace blackjack-ws = "Blackjack/WS";
import module namespace websocket = "http://basex.org/modules/ws";

import module namespace blackjack-main = "Blackjack/Main" at "blackjack-main.xqm";

 (:~
  : Module Name: Blackjack Websocket
  : Triggered if a player connects to a websocket:
  : @return console log with connected player and websocket-Id
  :)
declare
%ws-stomp:connect("/docbook_blackjack")
%updating
function blackjack-ws:stompconnect(){
    update:output(trace(concat("WS client connected with id ", websocket:id())))
};

 (:~
  : Triggered if a player disconnects from a websocket:
  :     If the player leaves the game -> delete this player from game
  : @return model changed game /if a player leaves the game
  :)
declare
%ws:close("/docbook_blackjack")
%updating
function blackjack-ws:stompdisconnect(){
    let $gameId := blackjack-ws:get(websocket:id(), "gameId")
    return (
        if (exists($blackjack-main:lobby/game[@id = $gameId])) then (
            let $playerId := blackjack-ws:get(websocket:id(), "playerId")
            let $game := blackjack-main:getGame($gameId)
            return (
                if (exists($game/players/player[@id=$playerId]/left)) then (
                    delete node $game/players/player[@id=$playerId]),
                update:output(trace(concat("WS client " , $playerId , " disconnected from game: ", $gameId)))
            )
        )
    )
};

 (:~
  : Triggered if a player subscribes to a websocket
  : saves playerId, gameId and applicationId to the websocket-Id
  : @return console log with connected player and game Ids
  :)
declare
%ws-stomp:subscribe("/docbook_blackjack")
%ws:header-param("param0", "{$game}")
%ws:header-param("param1", "{$gameId}")
%ws:header-param("param2", "{$playerId}")
%updating
function blackjack-ws:subscribe($game, $playerId, $gameId){
    websocket:set(websocket:id(), "playerId", $playerId),
    websocket:set(websocket:id(), "applicationId", "Blackjack"),
    websocket:set(websocket:id(), "gameId", $gameId),
    update:output(trace(concat("WS client with id: ", ws:id(), " and PlayerID: ", $playerId ," subscribed to ", $gameId)))
};


declare function blackjack-ws:getIDs(){
    websocket:ids()
};

 (:~
  : send massage via websocket
  : @data sended data
  : @path websocket-path, where to send the data
  :)
declare function blackjack-ws:send($data, $path){
    websocket:sendchannel(fn:serialize($data), $path)
};

 (:~
  : get information from a websocket-ID
  : @wsId the websocket-Id
  : @key asked information
  :)
declare function blackjack-ws:get($wsId, $key){
    websocket:get($wsId, $key)
};
