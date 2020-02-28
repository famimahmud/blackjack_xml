xquery version "3.1";

module namespace helper = "Blackjack/Helper";

(:~
 : Return random number from given interval [0, max]
 : @return  the calculated random integer
 :)
 declare function helper:getRandomInt($max as xs:integer) as xs:integer {
    (random:integer($max) + 1)
 };

(: declare function helper:getNewHandValue ($newCardSymbol as element(), $handValue as xs:integer) as xs:integer {
    let $value := if ($newCardSymbol = "J" or $newCardSymbol = "Q" or $newCardSymbol = "K") then 10
        else (if ($newCardSymbol = "A") then (if ($handValue > 11) then 1 else 11)
            else xs:integer($newCardSymbol))
    return ($handValue + $value)
 };:)
