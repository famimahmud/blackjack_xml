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
     let $hand := if ($playerID = "dealer") then game/dealer/hand
                    else ($blackjack-main:game/players/player[@id = $playerID]/hand)
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
                else (blackjack-main:calculateHandValueHelper($hand/card[position() > 1]) + xs:integer($hand/card[position() = 1]/value/node()))))
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
 : pay all players and change to bet-Phase
 : @return model change at player-wallets and player-pools
 :)
declare
%updating
function blackjack-main:payPhase(){
    for $playerId in blackjack-main:game/players/player/@id
    return (
        blackjack-main:payPlayer($playerId),
        delete node $blackjack-main:game/dealer/hand/card,
        replace value of node $blackjack-main:game/@onTurn with "bet"
    )
};
(:~
 : move the current turn to the given player
 : @playerID $playerID who will be paid
 : @return model change at player wallet and player pool
 :)
declare
%updating
function blackjack-main:payPlayer($playerID as xs:string){
    let $wallet := xs:integer(game/players/player[@id=$playerID]/wallet/node())
    let $poolBet := sum(game/players/player[@id=$playerID]/pool/chip/value)
    let $playerValue := blackjack-main:calculateHandValue($playerID)
    let $dealerValue := blackjack-main:calculateHandValue("dealer")
    return (
        delete node $blackjack-main:game/players/player[@id=$playerID]/pool/chip,
        (: check if playerhand is below 22 -> if not -> loss :)
        if ($playerValue < 22) then (
            (: check if playerhand = dealerhand  -> no gain :)
            if ( $playerValue = $dealerValue)
                then (replace node $blackjack-main:game/players/player[@id=$playerID]/wallet with ($wallet + $poolBet) )
                        (: check if playerhand > dealerhand  -> profit :)
                else (if ($playerValue > $dealerValue)
                        then (replace node $blackjack-main:game/players/player[@id=$playerID]/wallet with ($wallet + (2*$poolBet))))
        )
    )
};

(:~
 : put a chip into the pool of the player
 : @playerID $playerID of the player, who bets
 : @chipValue $chipValue of the bet chip
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:bet($playerId as xs:string, $chipValue as xs:integer){
    let $wallet := xs:integer($blackjack-main:game/players/player[@id=$playerID]/wallet/node())
    let $poolBet := sum($blackjack-main:game/players/player[@id=$playerID]/pool/chip/value)
    let $newChip := <chip><value>{$chipValue}</value></chip>
    return if (($chipValue = 10 or $chipValue = 50 or $chipValue = 100
            or $chipValue = 250 or $chipValue = 500 or $chipValue = 1000)
            and $chipValue <= $wallet)
            then (
                replace node $blackjack-main:game/players/player[@id=$playerId]/wallet with ($wallet - $chipValue),
                insert node $newChip into $blackjack-main:game/players/player[@id=$playerId]/pool
            )
};

(:~
 : give every player and the dealer two cards
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:handOutCards(){
    if ($blackjack-main:game/@onTurn = "bet") then (
        (: TO-DO (updaten der Datenbank nach der ersten Karte für den dealer nötig:)
    )
};

(:~
 : move Turn to next player or to dealer
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
