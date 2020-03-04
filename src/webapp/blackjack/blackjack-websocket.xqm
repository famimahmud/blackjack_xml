xquery version "3.0";

module namespace blackjack-ws = "Blackjack/WS";
import module namespace websocket = "http://basex.org/modules/ws";

import module namespace blackjack-main = "Blackjack/Main" at "blackjack-main.xqm";

declare
%ws-stomp:connect("/blackjack")
%updating
function blackjack-ws:stompconnect(){
    update:output(trace(concat("WS client connected with id ", websocket:id())))
};

declare
%ws:close("/blackjack")
%updating
function blackjack-ws:stompdisconnect(){
    let $gameId := blackjack-ws:get(websocket:id(), "gameId")
    return (
        if (exists($blackjack-main:games/game[@id = $gameId])) then (
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

declare
%ws-stomp:subscribe("/blackjack")
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

declare function blackjack-ws:send($data, $path){
    websocket:sendchannel(fn:serialize($data), $path)
};

declare function blackjack-ws:get($key, $value){
    websocket:get($key, $value)
};
