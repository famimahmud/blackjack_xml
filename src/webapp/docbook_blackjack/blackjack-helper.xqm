xquery version "3.1";
(:~
 : This module is used for helper functions like generating a Deck or a random number.
 : The generated random number determines Ids or draws random cards out of the deck.
 :
 : @author   Moritz Issig, Patryk Bazoza, Fami Mahmud
 : @see      e.g. chapter helper in the documentation
 : @version  1.0
 :)

module namespace blackjack-helper = "Blackjack/Helper";

declare variable $blackjack-helper:players := db:open("DocBook_Players")/players;
declare variable $blackjack-helper:lobby := db:open("DocBook_Lobby")/lobby;

(:~
 : Return random number from given interval [1, max]
 : @max the maximum for the ramdon integer
 : @return  the calculated random integer
 :)
 declare function blackjack-helper:getRandomInt($max as xs:integer) as xs:integer {
    (random:integer($max) + 1)
 };

 (:~
  : Return random number from given interval [min, max]
  : @min the minimum for the ramdon integer
  : @max the maximum for the ramdon integer
  : @return  the calculated random integer
  :)
  declare function blackjack-helper:getRandomIntFromRange($min as xs:integer, $max as xs:integer) as xs:integer {
     ((random:integer($max - $min) + 1) + $min)
  };

(:~
 : Creates new random player ID
 : @return new player ID
 :)
 declare function blackjack-helper:createPlayerId() as xs:integer {
    let $newID := blackjack-helper:getRandomIntFromRange(1000, 9999)
    return (
        if (boolean($blackjack-helper:players/player[@id = $newID])) then
            blackjack-helper:createPlayerId()
        else
            $newID
    )
 };

 (:~
  : Creates new random game ID
  : @return new game ID
  :)
  declare function blackjack-helper:createGameId() as xs:integer {
     let $newID := blackjack-helper:getRandomIntFromRange(1000, 9999)
     return (
         if (boolean($blackjack-helper:lobby/game[@id = $newID])) then
             blackjack-helper:createPlayerId()
         else
             $newID
     )
  };

 (:~
  : Check whether player exists in player database
  : @playerName name of the searched player
  : @playerId Id of the searched player
  : @return boolean returning existence
  :)
  declare function blackjack-helper:playerExists($playerName as xs:string?, $playerId as xs:string?) as xs:boolean {
     if (not($playerName instance of xs:string) or not($playerId instance of xs:string)) then (
        false()
     ) else (
        exists($blackjack-helper:players/player[@name = $playerName and @id = $playerId])
     )
  };

 (:~
  : Get player highscore from player database
  : @playerName name of the player with the searched highscore
  : @playerId Id of the player with the searched highscore
  : @return player highscore
  :)
  declare function blackjack-helper:getPlayerHighscore($playerName as xs:string, $playerId as xs:string) as xs:integer {
     $blackjack-helper:players/player[@name = $playerName and @id = $playerId]/@highscore
  };

   (:~
    : Get player scores from lobby database
    : @return player scores
    :)
    declare function blackjack-helper:getScoreBoard() {
       $blackjack-helper:lobby/scores
    };
