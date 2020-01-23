xquery version "3.0";

module namespace blackjack-main = "Blackjack/Main";
import module namespace blackjack-helper = "Blackjack/Helper" at "blackjack-helper.xqm";

declare variable $blackjack-main:game := db:open("Game")/game;
declare variable $blackjack-main:deck := db:open("Deck")/deck;
declare variable $blackjack-main:players := db:open("Players")/players;
declare variable $blackjack-main:lobby := db:open("Lobby")/lobby;


(:~
 : Deck gets shuffled
 : @return the shuffled deck
 :)
declare
%private
function blackjack-main:shuffleDeck() {
    let $ret := $blackjack-main:deck
    return ($ret)
};

declare
%updating
function blackjack-main:newRound($playerName as xs:string, $playerID as xs:integer) { (:$player as element(player)) {:)
    let $deck := blackjack-main:generateDeck()
    let $game :=
        <game>
            {$deck}

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
            {$blackjack-main:deck/card}
            {$blackjack-main:deck/card}
            {$blackjack-main:deck/card}
            {$blackjack-main:deck/card}
            {$blackjack-main:deck/card}
            {$blackjack-main:deck/card}
        </deck>
    return ($deck)
 };

(:~
 : Remove given player from list of Players
 : @playerID $playerID who will be deleted
 : @return model change to remove player
 :)
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
    let $card := $blackjack-main:game/deck/card[position() = $randomNumber]
    let $revealedCard := <card hidden="false">{$card/type}{$card/value}</card>
    return (
            delete node $blackjack-main:game/deck/card[position() = $randomNumber],
            insert node $revealedCard into $blackjack-main:game/players/player[@id = $playerID]/hand
    )
 };

 (:~
  : Calculates the maxValue of Hand
  : @player, with the hand
  : @return interger with the closes value to 21
  :)
  declare
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
  function blackjack-main:calculateHandValueHelper($hand as element()+) as xs:integer {
     let $result :=  if (empty($hand/card)) then 0
        else ( if ($hand/card[position() = 1]/value = "J"
                or $hand/card[position() = 1]/value = "Q"
                or $hand/card[position() = 1]/value = "K")
            then (blackjack-main:calculateHandValueHelper($hand/card[position() > 1]) + 10)
            else (if ($hand/card[position() = 1]/value = "A") then (blackjack-main:calculateHandValueHelper($hand/card[position() > 1] + 11))
                else (blackjack-main:calculateHandValueHelper($hand/card[position() > 1]) + $hand/card[position() = 1]/value)))
    return xs:integer($result)
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

(:~
 : move the current turn to the given player
 : @playerOnTurn $playerID whose turn it is next
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:moveTurn($playerOnTurn as xs:string){
    if ($playerOnTurn = $blackjack-main:game/@onTurn) then (
        let $newPlayerTurn := if($blackjack-main:game/@onTurn = game/players/player[last()]/@id ) then "dealer" else game/players/player[@id=$playerOnTurn]/following-sibling::*[1]/@id
        return (replace value of node $blackjack-main:game/@onTurn with $newPlayerTurn))
};

(:~
 : adding a player to the game
 : @playerID $playerID who will be added
 : @return model change to insert Player to the current game
 :)
declare
%updating
function blackjack-main:addPlayer($playerID as xs:string){
    let $newPlayer := $blackjack-main:players/player[@id=$playerID]
    return(insert node $newPlayer as last into $blackjack-main:game/players)
};

declare function blackjack-main:getGame(){
    $blackjack-main:game
};

declare function blackjack-main:getLobby(){
    $blackjack-main:lobby
};
