xquery version "3.0";

module namespace blackjack-main = "Blackjack/Main";
import module namespace blackjack-helper = "Blackjack/Helper" at "blackjack-helper.xqm";

declare variable $blackjack-main:game := db:open("Game")/game;
declare variable $blackjack-main:deck := db:open("Deck")/deck;

declare
%private
function blackjack-main:shuffleDeck() {
    let $ret := $blackjack-main:deck
    return ($ret)
};

declare
%updating
function blackjack-main:newRound($playerName as xs:string, $playerID as xs:integer) { (:$player as element(player)) {:)
    let $shuffledDeck := blackjack-main:shuffleDeck()
    let $game :=
        <game>
            <deck>
                $shuffledDeck
            </deck>

            <dealer onTurn="false">
                <hand>
                </hand>
            </dealer>

            <players>
                <player id="{$playerID}" name="{$playerName}">
                            <hand>
                            </hand>
                            <wallet>
                                500
                            </wallet>
                            <pool>
                            </pool>
                        </player>
            </players>
        </game>

    return (replace node $blackjack-main:game with $game)
};

(:~
 : Return random number from given interval [0, max]
 : @return  the calculated random integer
 :)
 declare function blackjack-main:generateDeck() as element(deck) {
    let $deck :=
        <deck>

        </deck>
    return ($deck)
 };

declare function blackjack-main:getGame(){
    $blackjack-main:game
};

declare
%updating
function blackjack-main:removePlayer($playerID as xs:string){
    delete node $blackjack-main:game/players/player[@id = $playerID]
};

(:~
 : Draw one card from the deck and add the card to the player hand
 : @player, who gets the drawn card
 : @deck from there the card will be drawn
 : @return model changes: (removing random card from deck and add same card(revealed) to playerHand)
 :)
 declare
 %updating
 function blackjack-main:drawCard($playerID as xs:string) {
    let $cardsInDeck := count($blackjack-main:game/deck/card)
    let $randomNumber := blackjack-helper:getRandomInt($cardsInDeck)
    let $card := count($blackjack-main:game/deck/card[position() = $randomNumber])
    return (
            delete node $blackjack-main:game/deck/card[position() = $randomNumber],
            replace value of node $card/@hidden with "false",
            insert node $card into $blackjack-main:game/players/player[@id = $playerID]/hand
    )
 };

 (:~ TO-DO
  : Calculates the maxValue of Hand
  : @player, with the hand
  : @return interger with the closes value to 21
  :)
  declare
  %updating
  function blackjack-main:calculateHandValue($playerID as xs:string) as xs:integer {
     let $hand := $blackjack-main:game/players/player[@id = $playerID]/hand
     return (blackjack-main:reduceHandValueWithAces(count($hand/card[value ="A"]), blackjack-main:calculateHandValueHelper($hand))
     )
  };
  (:~
   : Calculates the maxValue of a given Hand
   : @hand, a hand of cards
   : @return the maximal Value of the Hand (all Aces count 11)
   :)
  declare
  function blackjack-main:calculateHandValueHelper($hand as element(hand)) as xs:integer {
     let $result :=  if (empty($hand/card)) then 0
        else ( if ($hand/card[position() = 1]/value = "J"
                or $hand/card[position() = 1]/value = "Q"
                or $hand/card[position() = 1]/value = "K")
            then ($blackjack-main:calculateHandValueHelper($hand/card[position() > 1] + 10))
            else (if ($hand/card[position() = 1]/value = "A") then ($blackjack-main:calculateHandValueHelper($hand/card[position() > 1] + 11))
                else ($blackjack-main:calculateHandValueHelper($hand/card[position() > 1] + $hand/card[position() = 1]/value))))
    return $result
  };

  (:~
   : Reduces the HandValue by 10 for each Ace untill the value is smaller than 22
   : @numberOfAces number of Aces, which will be used to reduce by 10
   : @handValue the value of a previously calculated Hand
   : @return interger with the closes value to 21
   :)
  declare
  function blackjack-main:reduceHandValueWithAces($numberOfAces as xs:integer, $handValue as xs:integer) as xs:integer {
    let $result := if ($numberOfAces = 0 or $handValue < 22) then $handValue
        else (blackjack-main:reduceHandValueWithAces(($handValue - 10), $numberOfAces - 1))
    return $result
  };


declare
%updating
function blackjack-main:moveTurn($playerOnTurn as xs:string){
    let $newPlayerTurn := if($playerOnTurn = game/players/player[last()]/@id ) then "dealer" else game/players/player[@id=$playerOnTurn]/following-sibling::*[1]/@id
    return (replace value of node $blackjack-main:game/@onTurn with $newPlayerTurn)
};
