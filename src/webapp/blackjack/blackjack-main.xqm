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

(:~
  : initate a new Game by creating a new Game model
  : @playerName player who starts new Game
  : @playerID ID of player who starts new Game
  : @return model change
  :)

declare
%updating
function blackjack-main:newGame($playerName as xs:string, $playerID as xs:integer) {
      let $deck := blackjack-main:generateDeck()
      let $game :=
          <game round="1" onTurn="dealer" phase="bet">
              {$deck}
              <dealer>
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
                              <pool locked="false">
                              </pool>
                   </player>
              </players>
          </game>

      return (replace node $blackjack-main:game with $game)
  };

  (:~
  : initate a new Round by deleting hands and pools
  : @return model change
  :)
  declare
  %updating
  function blackjack-main:newRound () {
      let $deck := blackjack-main:generateDeck()
      let $newPool := <pool locked = "false"/>
      return (replace node $blackjack-main:game/deck with $deck,
              delete node $blackjack-main:game/players/player/hand/card,
              delete node $blackjack-main:game/dealer/hand/card,
              for $oldPool in $blackjack-main:game/players/player/pool
              return(
                 replace node $oldPool with $newPool
              )
      )
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
    let $cardsInHand := if ($playerID = "dealer") then $blackjack-main:game/dealer/hand/card
                        else $blackjack-main:game/players/player[@id = $playerID]/hand/card
    let $randomNumber := blackjack-helper:getRandomInt($cardsInDeck)
    let $card := $blackjack-main:game/deck/card[position() = $randomNumber]
    let $revealedCard := if ($playerID = "dealer" and count($blackjack-main:game/dealer/hand/card) = 0)
        (: first drawn card of the dealer is hidden :)
        then <card hidden="true">{$card/type}{$card/value}</card>
        else <card hidden="false">{$card/type}{$card/value}</card>
    let $handValue := blackjack-main:calculateHandValue(<hand>{$cardsInHand[@hidden="false"]}{$revealedCard[@hidden="false"]}</hand>)
    return (
            delete node $blackjack-main:game/deck/card[position() = $randomNumber],
            (if ($playerID = "dealer")
                then replace node $blackjack-main:game/dealer/hand with <hand sum="{$handValue}">{$cardsInHand}{$revealedCard}</hand>
                else replace node $blackjack-main:game/players/player[@id = $playerID]/hand with <hand sum="{$handValue}">{$cardsInHand}{$revealedCard}</hand>),
            if ($handValue > 20) then blackjack-main:moveTurn($playerID)
    )
 };

 (:~
  : Calculates the maxValue of Hand
  : @player, with the hand
  : @return interger with the closes value to 21
  :)
  declare
  function blackjack-main:calculateHandValue($hand as element()) as xs:integer {
     blackjack-main:reduceHandValueWithAces(count($hand/card[value ="A"]), blackjack-main:calculateHandValueHelper($hand))
  };
  (:~
   : Calculates the maxValue of a given Hand
   : @hand, a hand of cards
   : @return the maximal Value of the Hand (all Aces count 11)
   :)
  declare
  function blackjack-main:calculateHandValueHelper($hand as element()) as xs:integer {
     if (empty($hand/card)) then 0
        else ( if ($hand/card[position() = 1]/value = "J"
                or $hand/card[position() = 1]/value = "Q"
                or $hand/card[position() = 1]/value = "K")
            then (blackjack-main:calculateHandValueHelper(<hand>{$hand/card[position() > 1]}</hand>) + 10)
            else (if ($hand/card[position() = 1]/value = "A") then (blackjack-main:calculateHandValueHelper(<hand>{$hand/card[position() > 1]}</hand>) + 11)
                else (blackjack-main:calculateHandValueHelper(<hand>{$hand/card[position() > 1]}</hand>) + xs:integer($hand/card[position() = 1]/value/node()))))
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
    for $playerID in blackjack-main:game/players/player/@id
    return (
        blackjack-main:payPlayer($playerID),
        delete node $blackjack-main:game/dealer/hand/card,
        replace value of node $blackjack-main:game/@phase with "bet"
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
    let $wallet := xs:integer($blackjack-main:game/players/player[@id=$playerID]/wallet/node())
    let $poolBet := sum($blackjack-main:game/players/player[@id=$playerID]/pool/chip/value)
    let $playerValue := $blackjack-main:game/players/player[@id=$playerID]/hand/@sum
    let $dealerValue := $blackjack-main:game/dealer/hand/@sum
    return (
        replace node $blackjack-main:game/players/player[@id=$playerID]/pool with <pool locked="false"></pool>,
        delete node $blackjack-main:game/players/player[@id=$playerID]/hand/card,
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
function blackjack-main:bet($playerID as xs:string, $chipValue as xs:integer){
    let $wallet := xs:integer($blackjack-main:game/players/player[@id=$playerID]/wallet/node())
    let $poolBet := sum($blackjack-main:game/players/player[@id=$playerID]/pool/chip/value)
    let $newChip := <chip><value>{$chipValue}</value></chip>
    return if (($chipValue = 10 or $chipValue = 50 or $chipValue = 100
            or $chipValue = 250 or $chipValue = 500 or $chipValue = 1000)
            and $chipValue <= $wallet)
            then (
                replace node $blackjack-main:game/players/player[@id=$playerID]/wallet/node() with ($wallet - $chipValue),
                insert node $newChip into $blackjack-main:game/players/player[@id=$playerID]/pool
            )
};

(:~
 : confirm the bet of the given player
 : @playerID $playerID of the player, whos bets will be confirmed
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:confirmBet($playerID as xs:string){
    if ($blackjack-main:game/players/player[@id = $playerID]/pool/@locked = "false")
    then (
        replace node $blackjack-main:game/players/player[@id = $playerID]/pool
            with <pool locked="true">{$blackjack-main:game/players/player[@id = $playerID]/pool/chip}</pool>,
        (:check if all players confirmed their bets -> if true: hand out Cards:)
        if (count($blackjack-main:game/players/player/pool[@locked="true"]/@locked) >= (count($blackjack-main:game/players/player) - 1))
        then blackjack-main:handOutCards()
        )
};

(:~
 : give every player and the dealer two cards
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:handOutCards(){
    if ($blackjack-main:game/@phase = "bet") then (
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
       blackjack-main:moveTurnHelper($playerOnTurn))
};

(:~
 : move Turn to next player with less than 21 or to dealer
 : @playerOnTurn $playerID whose turn it is next
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:moveTurnHelper($playerOnTurn as xs:string){
        let $newPlayerTurn := if($playerOnTurn = $blackjack-main:game/players/player[last()]/@id )
            then "dealer"
            else $blackjack-main:game/players/player[@id=$playerOnTurn]/following-sibling::*[1]/@id
        return ( if ($newPlayerTurn = "dealer" or $blackjack-main:game/players/player[@id=$newPlayerTurn]/hand/@sum <= 20)
            then (
                replace value of node $blackjack-main:game/@onTurn with $newPlayerTurn,
                        (: TO-DO: update Datenbank und sende draw an Player, optional warte 1000ms:)
                        if ($newPlayerTurn = "dealer")
                            then blackjack-main:revealeDealerHand(),
                                 update:output(web:redirect("blackjack/dealerTurn"))
                )
                else (blackjack-main:moveTurnHelper($newPlayerTurn))
        )
};

declare
%updating
function blackjack-main:revealeDealerHand() {
    let $dealerHandValue := blackjack-main:calculateHandValue($blackjack-main:game/dealer/hand)
        let $firstCard := $blackjack-main:game/dealer/hand/card[position() = 1]
        return (if ($blackjack-main:game/@onTurn = "dealer") then (
                (replace node $blackjack-main:game/dealer/hand
                    with <hand sum="{$dealerHandValue}"><card hidden="false">{$firstCard/type}{$firstCard/value}</card>
                    {$blackjack-main:game/dealer/hand/card[position() > 1]}</hand>)))
};

(:~
 : dealer Turn
 : @return model change: dealer has drawn cards
 :)
declare
%updating
function blackjack-main:dealerTurn(){
    let $dealerHandValue := blackjack-main:calculateHandValue($blackjack-main:game/dealer/hand)
    return (if ($blackjack-main:game/@onTurn = "dealer") then (
            update:output(web:redirect("/blackjack/draw")),
            prof:sleep(1000), (: pause for 1000ms :)
            if ($dealerHandValue < 17) then
            blackjack-main:drawCard("dealer")))
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

declare function blackjack-main:getPlayers(){
    $blackjack-main:players
};