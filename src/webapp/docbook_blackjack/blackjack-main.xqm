xquery version "3.1";
(:~
 : Module Name: Blackjack Main
 : The main module contains functions to implement the game logic of the blackjack game.
 :
 : @author   Moritz Issig, Patryk Brzoza, Fami Mahmud
 : @see      e.g. chapter main game in the documentation
 : @version  1.0
 :)
module namespace blackjack-main = "Blackjack/Main";
import module namespace blackjack-helper = "Blackjack/Helper" at "blackjack-helper.xqm";

declare variable $blackjack-main:players := db:open("DocBook_Players")/players;
declare variable $blackjack-main:lobby := db:open("DocBook_Lobby")/lobby;

(:~
  : Initate a new Game by creating a new Game model
  : @gameId ID for the stated Game
  : @playerName player who starts new Game
  : @playerId ID of player who starts new Game
  : @singlePlayer flag: if true it's not possible to join the game
  : @return model change
  :)
declare
%updating
function blackjack-main:newGame($gameId as xs:integer, $playerName as xs:string, $playerId as xs:string, $singlePlayer as xs:string) {
      let $deck := blackjack-helper:generateDeck()
      let $game :=
          <game id="{$gameId}" singlePlayer="{$singlePlayer}" onTurn="noOne" phase="bet">
              {$deck}
              <dealer>
                  <hand>
                  </hand>
              </dealer>

              <players>
                  <player id="{$playerId}" name="{$playerName}">
                          <hand>
                          </hand>
                          <wallet>1000</wallet>
                          <pool locked="false"></pool>
                   </player>
              </players>
          </game>

      return (insert node $game into $blackjack-main:lobby)
  };


  (:~
  : Initate a new Round by refilling the deck and go to bet-phase
  : @gameId ID of the game, which start the new Round
  : @return model change
  :)
  declare
  %updating
  function blackjack-main:newRound ($gameId as xs:integer) {
      let $deck := blackjack-helper:generateDeck()
      return(
              replace node $blackjack-main:lobby/game[@id = $gameId]/deck with $deck,
              replace value of node $blackjack-main:lobby/game[@id = $gameId]/@onTurn with "noOne",
              replace value of node $blackjack-main:lobby/game[@id = $gameId]/@phase with "bet",
              for $disconnectedPlayer in $blackjack-main:lobby/game[@id = $gameId]/players/player[exists(disconnected)]
              return (delete node $disconnectedPlayer)
      )
  };


(:~
 : Draw one card from the deck, add the card to the player hand and calculate new HandValue
 : If the new HandValue is over 21 -> moveTurn to next Player (or to Dealer)
 : @gameId Id of the game, where the card is drawn
 : @playerId Id of player or "dealer", who gets the drawn card
 : @return model changes: (removing random card from deck and add same card(revealed) to hand)
 :)
 declare
 %updating
 function blackjack-main:drawCard($gameId as xs:integer, $playerId as xs:string) {
    let $cardsInDeck := count($blackjack-main:lobby/game[@id = $gameId]/deck/card)
    let $cardsInHand := if ($playerId = "dealer") then $blackjack-main:lobby/game[@id = $gameId]/dealer/hand/card
                        else $blackjack-main:lobby/game[@id = $gameId]/players/player[@id = $playerId]/hand/card
    let $randomNumber := blackjack-helper:getRandomInt($cardsInDeck)
    (: draw a card from a random position of the sorted deck :)
    let $card := $blackjack-main:lobby/game[@id = $gameId]/deck/card[position() = $randomNumber]
    let $revealedCard := if ($playerId = "dealer" and count($blackjack-main:lobby/game[@id = $gameId]/dealer/hand/card) = 0)
        (: first drawn card of the dealer is hidden :)
        then <card hidden="true">{$card/type}{$card/value}</card>
        else <card hidden="false">{$card/type}{$card/value}</card>
    let $handValue := blackjack-main:calculateHandValue(<hand>{$cardsInHand[@hidden="false"]}{$revealedCard[@hidden="false"]}</hand>)
    return (
            (: remove card from deck :)
            delete node $blackjack-main:lobby/game[@id = $gameId]/deck/card[position() = $randomNumber],
            (: add card to hand :)
            (if ($playerId = "dealer")
                then replace node $blackjack-main:lobby/game[@id = $gameId]/dealer/hand with <hand sum="{$handValue}">{$cardsInHand}{$revealedCard}</hand>
                else replace node $blackjack-main:lobby/game[@id = $gameId]/players/player[@id = $playerId]/hand with <hand sum="{$handValue}">{$cardsInHand}{$revealedCard}</hand>),
            (: if new handValue is over 21 -> move turn no next player :)
            if ($handValue > 21 and $playerId != "dealer" and $blackjack-main:lobby/game[@id = $gameId]/@phase = "play") then blackjack-main:moveTurn($gameId, $playerId)
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
   : Rekursiv Helper-Function for calculating the maxValue of a given Hand
   : @hand, a hand of cards / remove one card recursivly
   : @return the maximal Value of the Hand (all Aces count 11)
   :)
  declare
  function blackjack-main:calculateHandValueHelper($hand as element()) as xs:integer {
     let $firstCardValue :=
        if (empty($hand/card[position() = 1])) then 0
        else ( if ($hand/card[position() = 1]/value = "J"
                or $hand/card[position() = 1]/value = "Q"
                or $hand/card[position() = 1]/value = "K")
                then (10)
                    else (if ($hand/card[position() = 1]/value = "A")
                        then (11)
                            else (xs:integer($hand/card[position() = 1]/value/node()))))
     return (
        if (empty($hand/card[position() > 1])) then $firstCardValue
            else (blackjack-main:calculateHandValueHelper(<hand>{$hand/card[position() > 1]}</hand>) + xs:integer($firstCardValue))
     )
  };


  (:~
   : Reduces the HandValue recursivly by 10 for each Ace untill the value is smaller than 22 or no Aces are left
   : @numberOfAces number of Aces, which will be used to reduce by 10
   : @handValue the value of a previously calculated Hand
   : @return interger with the closes value to 21
   :)
  declare
  function blackjack-main:reduceHandValueWithAces($numberOfAces as xs:integer, $handValue as xs:integer) as xs:integer {
    let $result := if ($numberOfAces = 0 or $handValue < 22) then $handValue
        else (blackjack-main:reduceHandValueWithAces(($numberOfAces - 1), ($handValue - 10)))
    return $result
  };


(:~
 : pay all players and start new round
 : @gameId Id of the game, where the players will be paid out
 : @return model change at player-wallets and player-pools
 :)
declare
%updating
function blackjack-main:payPlayers($gameId as xs:integer){
    (: remove dealer hand:)
    for $playerId in $blackjack-main:lobby/game[@id = $gameId]/players/player/@id
        return (
            blackjack-main:payPlayer($gameId, $playerId)
        ),
    replace node $blackjack-main:lobby/game[@id = $gameId]/dealer/hand with <hand sum="0"/>,
    blackjack-main:newRound($gameId)
};


(:~
 : pays out given player and removes the cards form the hand
 : if the player loses the game and his wallet is empty -> remove him from the game
 : @gameId Id of the game, where the player will be paid out
 : @playerId Id of the player, who will be paid
 : @return model change at player wallet, player pool and player hand
 :)
declare
%updating
function blackjack-main:payPlayer($gameId as xs:integer, $playerId as xs:string){
    let $wallet := xs:integer($blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/wallet/node())
    let $poolBet := sum($blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/pool/chip/value)
    let $playerValue := $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/hand/@sum
    let $dealerValue := $blackjack-main:lobby/game[@id = $gameId]/dealer/hand/@sum
    return (
        if (($playerValue > 21 or ($playerValue < $dealerValue and $dealerValue < 22 ))
            and $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/wallet < 10)
            then delete node $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]
            else (
                replace node $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/pool with <pool locked="false"/>,
                replace node $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/hand with <hand sum="0"/>,
                (: check if playerhand is below 22 -> if not -> loss :)
                if ($playerValue < 22) then (
                    (: check if playerhand = dealerhand  -> no gain :)
                    if ( $playerValue = $dealerValue)
                        then (replace node $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/wallet/node() with ($wallet + $poolBet) )
                                (: check if playerhand > dealerhand or dealerhand > 21 -> profit :)
                        else (if ($playerValue > $dealerValue or $dealerValue > 21)
                                then ( if ($playerValue = 21 )
                                        (: blackjack pays 3:2 :)
                                    then replace node $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/wallet/node() with ($wallet + (2.5*$poolBet))
                                    else replace node $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/wallet/node() with ($wallet + (2*$poolBet))))
                )
        )
    )
};


(:~
 : put a chip into the pool of the player
 : @gameId Id of the game, where the bet will be added
 : @playerId $playerId of the player, who bets
 : @chipValue $chipValue of the bet chip
 : @return model change with added chip in the player pool and reduced player wallet
 :)
declare
%updating
function blackjack-main:bet($gameId as xs:integer, $playerId as xs:string, $chipValue as xs:integer){
    let $wallet := xs:integer($blackjack-main:lobby/game[@id=$gameId]/players/player[@id=$playerId]/wallet/node())
    let $poolBet := sum($blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/pool/chip/value)
    let $newChip := <chip><value>{$chipValue}</value></chip>
    return if (($chipValue = 10 or $chipValue = 50 or $chipValue = 100
            or $chipValue = 250 or $chipValue = 500 or $chipValue = 1000)
            and $chipValue <= $wallet)
            then (
                replace node $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/wallet/node() with ($wallet - $chipValue),
                insert node $newChip into $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/pool
            )
};


(:~
 : confirm the bet of the given player / if the player confirmed last -> change to deal-phase
 : @gameId Id of the game, where the player-bets will be confirmed
 : @playerId $playerId of the player, whos bets will be confirmed
 : @return model change with locked player pool 
 :)
declare
%updating
function blackjack-main:confirmBet($gameId as xs:integer, $playerId as xs:string){
    let $pool := $blackjack-main:lobby/game[@id = $gameId]/players/player[@id = $playerId]/pool
    return if(($pool/@locked = "false") and ((count($pool/chip)>0) or exists($blackjack-main:lobby/game[@id = $gameId]/players/player[@id = $playerId]/left)))
    then (
        replace node $blackjack-main:lobby/game[@id = $gameId]/players/player[@id = $playerId]/pool
            with <pool locked="true">{$blackjack-main:lobby/game[@id = $gameId]/players/player[@id = $playerId]/pool/chip}</pool>,
        (:check if all players confirmed their bets -> if true: change to deal-Phase and hand out Cards:)
        if (count($blackjack-main:lobby/game[@id = $gameId]/players/player[not(exists(disconnected))]/pool[@locked="true"]/@locked) >= (count($blackjack-main:lobby/game[@id = $gameId]/players/player[not(exists(disconnected))]) - 1))
        then (
            replace value of node $blackjack-main:lobby/game[@id = $gameId]/@phase with "deal",
            update:output(web:redirect(concat("/docbook_blackjack/", $gameId, "/dealPhase")))
        )
    )
};

(:~
 : gives every player and the dealer one card
 : @gameId Id of the game, where the cards will be handed out
 : @return model change with one card more in every hand
 :)
declare
%updating
function blackjack-main:handOutOneCardToEach($gameId as xs:integer){
    if ($blackjack-main:lobby/game[@id = $gameId]/@phase = "deal") then (
        for $playerId in ($blackjack-main:lobby/game[@id = $gameId]/players/player/@id, "dealer")
            return
                blackjack-main:drawCard($gameId, $playerId)
    )
};


(:~
 : give every player and the dealer two cards (DB-update between first and second card)
 : @gameId Id of the game, where the cards will be handed out
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:dealPhase($gameId as xs:integer){
    if ($blackjack-main:lobby/game[@id = $gameId]/@phase = "deal") then (
        blackjack-main:handOutOneCardToEach($gameId),
        update:output(web:redirect(concat("/docbook_blackjack/", $gameId, "/handOutOneCardToEach")))
    )
};


(:~
 : move Turn to next player or to dealer
 : @gameId Id of the game, where the turn moves
 : @playerOnTurn $playerId whose turn it is next
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:moveTurn($gameId as xs:integer, $playerOnTurn as xs:string){
    if ($playerOnTurn = $blackjack-main:lobby/game[@id = $gameId]/@onTurn
        or $blackjack-main:lobby/game[@id = $gameId]/@onTurn = "noOne") then (
       blackjack-main:moveTurnHelper($gameId, $playerOnTurn))
};


(:~
 : Recursiv helper-function ,which moves Turn to next player with less than 22 or to dealer
 : If the turn is moved to dealer -> start DealerTurn
 : @gameId Id of the game, where the turn moves
 : @playerOnTurn $playerId whose turn it is now
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:moveTurnHelper($gameId as xs:integer, $playerOnTurn as xs:string){
        let $newPlayerTurn := if($playerOnTurn = $blackjack-main:lobby/game[@id = $gameId]/players/player[last()]/@id )
            then "dealer"
            else if ($playerOnTurn = "dealer") then $blackjack-main:lobby/game[@id = $gameId]/players/player[position() = 1]/@id
                 else $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerOnTurn]/following-sibling::*[1]/@id
                 (: checks if the hand of the next player is "dealer" or if the player left or disconnected from the game -> if false: move Turn again :)
        return ( if ($newPlayerTurn = "dealer" or (not(exists($blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$newPlayerTurn]/left))
                                                    and not(exists($blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$newPlayerTurn]/disconnected))))
            then (
                replace value of node $blackjack-main:lobby/game[@id = $gameId]/@onTurn with $newPlayerTurn,
                if ($newPlayerTurn = "dealer")
                    then    (: if next player is dealer: reveal the dealer-cards and start dealerTurn:)
                        let $dealerHandValue := blackjack-main:calculateHandValue($blackjack-main:lobby/game[@id = $gameId]/dealer/hand)
                        let $firstCard := $blackjack-main:lobby/game[@id = $gameId]/dealer/hand/card[position() = 1]
                        return (
                            replace node $blackjack-main:lobby/game[@id = $gameId]/dealer/hand
                                    with <hand sum="{$dealerHandValue}"><card hidden="false">{$firstCard/type}{$firstCard/value}</card>
                                                {$blackjack-main:lobby/game[@id = $gameId]/dealer/hand/card[position() > 1]}</hand>,
                            update:output(web:redirect(concat("/docbook_blackjack/", $gameId, "/dealerTurn"))),
                            update:output(web:redirect(concat("/docbook_blackjack/", $gameId))))
                )
                else (blackjack-main:moveTurnHelper($gameId, $newPlayerTurn))
        )
};

(:~
 : dealer Turn: dealer draws cards recursivly untill he's over 16. When change to pay-phase
 : @gameId Id of the game, where the dealerTurn starts
 : @return model change: dealer has drawn cards
 :)
declare
%updating
function blackjack-main:dealerTurn($gameId as xs:integer){
    if ($blackjack-main:lobby/game[@id = $gameId]/@onTurn = "dealer") then (
    let $dealerHandValue := blackjack-main:calculateHandValue($blackjack-main:lobby/game[@id = $gameId]/dealer/hand)
    return (
            if ($dealerHandValue < 17)
            then (blackjack-main:drawCard($gameId, "dealer"),
            update:output(web:redirect(concat("/docbook_blackjack/", $gameId, "/dealerTurn"))))
            else replace value of node $blackjack-main:lobby/game[@id = $gameId]/@phase with "pay",
            if(exists($blackjack-main:lobby/game[@id = $gameId]/players/player/left) ) then (
                        let $parameters := map {
                                    "playerName": $blackjack-main:lobby/game[@id = $gameId]/players/player[exists(left)]/@name,
                                    "playerId": $blackjack-main:lobby/game[@id = $gameId]/players/player[exists(left)]/@id,
                                    "fromGameId": $gameId
                                }
                                return update:output(web:redirect("/docbook_blackjack/lobby", $parameters)))
                        else update:output(web:redirect(concat("/docbook_blackjack/", $gameId)))
    ))
};


(:~
 : adding a player to the game if player cant join -> redirect him to lobby
 : @gameId Id of the game, where the player will be added
 : @playerId $playerId who will be added
 : @return model change to insert Player to the current game
 :)
declare
%updating
function blackjack-main:addPlayer($gameId as xs:integer, $playerId as xs:string){
    if (exists($blackjack-main:players/player[@id = $playerId])
        and (exists($blackjack-main:lobby/game[@id = $gameId]/players/player[@id = $playerId])
            or count($blackjack-main:lobby/game[@id = $gameId]/players/player) < 7)
        and (exists($blackjack-main:lobby/game[@id = $gameId]/players/player[@id = $playerId])
            or $blackjack-main:lobby/game[@id = $gameId]/@phase = "bet")
        and $blackjack-main:lobby/game[@id = $gameId]/@singlePlayer = "false")
        then(
            let $playerName := $blackjack-main:players/player[@id = $playerId]/@name
            let $newPlayer :=
                  <player id="{$playerId}" name="{$playerName}">
                          <hand/>
                          <wallet>1000</wallet>
                          <pool locked="false"/>
                   </player>
    return ( (if (empty($blackjack-main:lobby/game[@id = $gameId]/players/player[@id = $playerId])) then
                insert node $newPlayer as last into $blackjack-main:lobby/game[@id = $gameId]/players),
            update:output(web:redirect(concat("/docbook_blackjack/", $gameId, "/join?playerId=", $playerId))))
    ) else (
        let $parameters := map {"playerName": blackjack-helper:getPlayerName($playerId),
                                "playerId": $playerId }
        return update:output(web:redirect("/docbook_blackjack/lobby", $parameters)))
};

(:~
 : Inserts player score to score list to compute highscore board
 : @gameId Id of the game, where the player achived the score
 : @playerId ID of the player to be inserted
 : @return New score board
 :)
declare
%updating
function blackjack-main:addHighscore($gameId as xs:integer, $playerId as xs:string){
    let $playerName := string($blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/@name)
    let $playerScore := $blackjack-main:lobby/game[@id = $gameId]/players/player[@id=$playerId]/wallet/text() -1000
    let $currentHighscore := $blackjack-main:players/player[@id=$playerId]/@highscore
    let $newEntry :=
    <score name="{$playerName}">{$playerScore}</score>
    return (
        if ($playerScore > 0) then (
            (: Replace old highscore value with new highscore in player database :)
            if ($playerScore > $currentHighscore) then (
                replace value of node $blackjack-main:players/player[@id=$playerId]/@highscore with $playerScore
            ),
            (: Add new score to score database :)
            insert node $newEntry as last into $blackjack-main:lobby/scores)
        )
};

(:~
 : Leave game: save player highscore.
 : @gameId ID of the game to remove the player
 : @playerId ID of the player, who leaves the game
 : @return Model change in highscore and lobby database
 :)
declare
%updating
function blackjack-main:leaveGame($gameId as xs:integer, $playerId as xs:string){
    blackjack-main:addHighscore($gameId, $playerId),
    (: if the leaving player was the last player who didn't confimed his bet -> move to dealPhase :)
    if ($blackjack-main:lobby/game[@id = $gameId]/@phase = "bet") then (
        let $pool := $blackjack-main:lobby/game[@id = $gameId]/players/player[@id = $playerId]/pool
            return if(($pool/@locked = "false"))
            then (
                (:check if all players confirmed their bets -> if true: change to deal-Phase and hand out Cards:)
                if (count($blackjack-main:lobby/game[@id = $gameId]/players/player[not(exists(disconnected))]/pool[@locked="true"]/@locked) >= (count($blackjack-main:lobby/game[@id = $gameId]/players/player[not(exists(disconnected))]) - 1))
                then (
                    replace value of node $blackjack-main:lobby/game[@id = $gameId]/@phase with "deal",
                    update:output(web:redirect(concat("/docbook_blackjack/", $gameId, "/dealPhase")))
                )
    )),
    (: if the leaving player was on turn -> moveTurn :)
    if ($blackjack-main:lobby/game[@id = $gameId]/@phase = "play" and $blackjack-main:lobby/game[@id = $gameId]/@onTurn = $playerId)
        then blackjack-main:moveTurn($gameId, $playerId)
};

(:~
   : End game: save player highscores and remove game.
   : @gameId ID of the game to remove the player
   : @return Model change in highscore and lobby database
   :)
  declare
  %updating
  function blackjack-main:endGame($gameId as xs:integer){
      (: Save scores of all players :)
      for $playerId in $blackjack-main:lobby/game[@id = $gameId]/players/player/@id
      return blackjack-main:addHighscore($gameId, $playerId),
      (: Remove game from game directory :)
      delete node $blackjack-main:lobby/game[@id = $gameId]
  };

declare function blackjack-main:getGame($gameId as xs:integer){
    $blackjack-main:lobby/game[@id = $gameId]
};


declare function blackjack-main:getLobby(){
    $blackjack-main:lobby
};


declare function blackjack-main:getPlayers(){
    $blackjack-main:players
};
