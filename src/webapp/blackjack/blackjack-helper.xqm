xquery version "3.1";

module namespace blackjack-helper = "Blackjack/Helper";

declare variable $blackjack-helper:players := db:open("Players")/players;
declare variable $blackjack-helper:games := db:open("Games")/games;
declare variable $blackjack-helper:highscores := db:open("Highscores");

(:~
 : Return random number from given interval [0, max]
 : @return  the calculated random integer
 :)
 declare function blackjack-helper:getRandomInt($max as xs:integer) as xs:integer {
    (random:integer($max) + 1)
 };


 (:~
  : Return random number from given interval [min, max]
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
         if (boolean($blackjack-helper:games/game[@id = $newID])) then
             blackjack-helper:createPlayerId()
         else
             $newID
     )
  };


 (:~
  : Check whether player exists in player database
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
  : @return player highscore
  :)
  declare function blackjack-helper:getPlayerHighscore($playerName as xs:string, $playerId as xs:string) as xs:integer {
     $blackjack-helper:players/player[@name = $playerName and @id = $playerId]/@highscore
  };


   (:~
    : Get player highscore from player database
    : @return player highscore
    :)
    declare function blackjack-helper:getHighscoreBoard() {
       $blackjack-helper:highscores
    };


(: declare function helper:getNewHandValue ($newCardSymbol as element(), $handValue as xs:integer) as xs:integer {
    let $value := if ($newCardSymbol = "J" or $newCardSymbol = "Q" or $newCardSymbol = "K") then 10
        else (if ($newCardSymbol = "A") then (if ($handValue > 11) then 1 else 11)
            else xs:integer($newCardSymbol))
    return ($handValue + $value)
 };:)
