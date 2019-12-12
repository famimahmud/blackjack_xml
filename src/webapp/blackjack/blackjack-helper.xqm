xquery version "3.0";

module namespace helper = "Blackjack/Helper";

(:~
 : Return random number from given interval [0, max]
 : @return  the calculated random integer
 :)
 declare function helper:getRandomInt($max as xs:integer) as xs:integer {
    random:integer($max + 1)
 };