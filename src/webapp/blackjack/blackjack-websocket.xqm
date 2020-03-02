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
    update:output(trace(concat("WS client disconnected with id ", websocket:id())))
};

declare
%ws-stomp:subscribe("/blackjack")
%ws:header-param("param0", "{$game}")
%ws:header-param("param1", "{$playerID}")
%updating
function blackjack-ws:subscribe($game, $playerID){
    websocket:set(websocket:id(), "playerID", $playerID),
    websocket:set(websocket:id(), "applicationID", "ttt"),
    update:output(trace(concat("WS client with id ", ws:id(), " subscribed to ", $game, "/", $playerID)))
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