xquery version "3.1";

module namespace blackjack-helper = "Blackjack/Helper";

declare variable $blackjack-helper:players := db:open("Players")/players;

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


(: declare function helper:getNewHandValue ($newCardSymbol as element(), $handValue as xs:integer) as xs:integer {
    let $value := if ($newCardSymbol = "J" or $newCardSymbol = "Q" or $newCardSymbol = "K") then 10
        else (if ($newCardSymbol = "A") then (if ($handValue > 11) then 1 else 11)
            else xs:integer($newCardSymbol))
    return ($handValue + $value)
 };:)
