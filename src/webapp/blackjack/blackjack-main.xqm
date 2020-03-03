xquery version "3.1";

module namespace blackjack-main = "Blackjack/Main";
import module namespace blackjack-helper = "Blackjack/Helper" at "blackjack-helper.xqm";

declare variable $blackjack-main:deck := db:open("Deck")/deck;
declare variable $blackjack-main:players := db:open("Players")/players;
declare variable $blackjack-main:games := db:open("Games")/games;
declare variable $blackjack-main:highscores := db:open("Highscores")/highscores;

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
  : Initate a new Game by creating a new Game model
  : @playerName player who starts new Game
  : @playerId ID of player who starts new Game
  : @return model change
  :)

declare
%updating
function blackjack-main:newGame($gameId as xs:integer, $playerName as xs:string, $playerId as xs:string, $singlePlayer as xs:string) {
      let $deck := blackjack-main:generateDeck()
      let $game :=
          <game id="{$gameId}" singlePlayer="{$singlePlayer}" round="1" maxRounds="10" onTurn="{$playerId}" phase="bet">
              {$deck}
              <dealer>
                  <hand>
                  </hand>
              </dealer>

              <players>
                  <player id="{$playerId}" name="{$playerName}">
                          <hand>
                          </hand>
                          <wallet>500</wallet>
                          <pool locked="false"></pool>
                   </player>
              </players>
          </game>

      return (insert node $game into $blackjack-main:games)
  };


  (:~
  : Initate a new Round by deleting hands and pools
  : @return model change
  :)
  declare
  %updating
  function blackjack-main:newRound ($gameId as xs:integer) {
      let $deck := blackjack-main:generateDeck()
      return (replace node $blackjack-main:games/game[@id = $gameId]/deck with $deck,
              replace value of node $blackjack-main:games/game[@id = $gameId]/@onTurn
                    with "noone",
              replace value of node $blackjack-main:games/game[@id = $gameId]/@phase with "bet"
      )
      (:websocket draw:)
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
 : @playerId $playerId who will be deleted
 : @return model change to remove player
 :)
declare
%updating
function blackjack-main:removePlayer($gameId as xs:integer, $playerId as xs:string){
    delete node $blackjack-main:games/game[@id = $gameId]/players/player[@id = $playerId]
};


(:~
 : Draw one card from the deck and add the card to the player hand
 : @player, who gets the drawn card
 : @deck from there the card will be drawn
 : @return model changes: (removing random card from deck and add same card(revealed) to playerHand)
 :)
 declare
 %updating
 function blackjack-main:drawCard($gameId as xs:integer, $playerId as xs:string) {
    let $cardsInDeck := count($blackjack-main:games/game[@id = $gameId]/deck/card)
    let $cardsInHand := if ($playerId = "dealer") then $blackjack-main:games/game[@id = $gameId]/dealer/hand/card
                        else $blackjack-main:games/game[@id = $gameId]/players/player[@id = $playerId]/hand/card
    let $randomNumber := blackjack-helper:getRandomInt($cardsInDeck)
    let $card := $blackjack-main:games/game[@id = $gameId]/deck/card[position() = $randomNumber]
    let $revealedCard := if ($playerId = "dealer" and count($blackjack-main:games/game[@id = $gameId]/dealer/hand/card) = 0)
        (: first drawn card of the dealer is hidden :)
        then <card hidden="true">{$card/type}{$card/value}</card>
        else <card hidden="false">{$card/type}{$card/value}</card>
    let $handValue := blackjack-main:calculateHandValue(<hand>{$cardsInHand[@hidden="false"]}{$revealedCard[@hidden="false"]}</hand>)
    return (
            delete node $blackjack-main:games/game[@id = $gameId]/deck/card[position() = $randomNumber],
            (if ($playerId = "dealer")
                then replace node $blackjack-main:games/game[@id = $gameId]/dealer/hand with <hand sum="{$handValue}">{$cardsInHand}{$revealedCard}</hand>
                else replace node $blackjack-main:games/game[@id = $gameId]/players/player[@id = $playerId]/hand with <hand sum="{$handValue}">{$cardsInHand}{$revealedCard}</hand>),
            if ($handValue > 20 and $playerId != "dealer" and $blackjack-main:games/game[@id = $gameId]/@phase = "play") then blackjack-main:moveTurn($gameId, $playerId)
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
   : Reduces the HandValue by 10 for each Ace untill the value is smaller than 22
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
 : pay all players and change to bet-Phase
 : @return model change at player-wallets and player-pools
 :)
declare
%updating
function blackjack-main:payPlayers($gameId as xs:integer){
    (: remove dealer hand:)
    replace node $blackjack-main:games/game[@id = $gameId]/dealer/hand with <hand sum="0"/>,
    for $playerId in $blackjack-main:games/game[@id = $gameId]/players/player/@id
        return (
            blackjack-main:payPlayer($gameId, $playerId)
        ),
    blackjack-main:newRound($gameId)
};


(:~
 : move the current turn to the given player
 : @playerId $playerId who will be paid
 : @return model change at player wallet and player pool
 :)
declare
%updating
function blackjack-main:payPlayer($gameId as xs:integer, $playerId as xs:string){
    let $wallet := xs:integer($blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/wallet/node())
    let $poolBet := sum($blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/pool/chip/value)
    let $playerValue := $blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/hand/@sum
    let $dealerValue := $blackjack-main:games/game[@id = $gameId]/dealer/hand/@sum
    return (
        replace node $blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/pool with <pool locked="false"></pool>,
        replace node $blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/hand with <hand sum="0"/>,
        (: check if playerhand is below 22 -> if not -> loss :)
        if ($playerValue < 22) then (
            (: check if playerhand = dealerhand  -> no gain :)
            if ( $playerValue = $dealerValue)
                then (replace node $blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/wallet/node() with ($wallet + $poolBet) )
                        (: check if playerhand > dealerhand  -> profit :)
                else (if ($playerValue > $dealerValue or $dealerValue > 21)
                        then (replace node $blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/wallet/node() with ($wallet + (2*$poolBet))))
        )
    )
};


(:~
 : put a chip into the pool of the player
 : @playerId $playerId of the player, who bets
 : @chipValue $chipValue of the bet chip
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:bet($gameId as xs:integer, $playerId as xs:string, $chipValue as xs:integer){
    let $wallet := xs:integer($blackjack-main:games/game[@id=$gameId]/players/player[@id=$playerId]/wallet/node())
    let $poolBet := sum($blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/pool/chip/value)
    let $newChip := <chip><value>{$chipValue}</value></chip>
    return if (($chipValue = 10 or $chipValue = 50 or $chipValue = 100
            or $chipValue = 250 or $chipValue = 500 or $chipValue = 1000)
            and $chipValue <= $wallet)
            then (
                replace node $blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/wallet/node() with ($wallet - $chipValue),
                insert node $newChip into $blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/pool
            )
};


(:~
 : confirm the bet of the given player
 : @playerId $playerId of the player, whos bets will be confirmed
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:confirmBet($gameId as xs:integer, $playerId as xs:string){
    if ($blackjack-main:games/game[@id = $gameId]/players/player[@id = $playerId]/pool/@locked = "false")
    then (
        replace node $blackjack-main:games/game[@id = $gameId]/players/player[@id = $playerId]/pool
            with <pool locked="true">{$blackjack-main:games/game[@id = $gameId]/players/player[@id = $playerId]/pool/chip}</pool>,
        (:check if all players confirmed their bets -> if true: hand out Cards:)
        if (count($blackjack-main:games/game[@id = $gameId]/players/player/pool[@locked="true"]/@locked) >= (count($blackjack-main:games/game[@id = $gameId]/players/player) - 1))
        then (
            replace value of node $blackjack-main:games/game[@id = $gameId]/@phase with "deal",
            update:output(web:redirect(concat("/blackjack/", $gameId, "/dealPhase")))
        )
    )
};


declare
%updating
function blackjack-main:handOutOneCardToEach($gameId as xs:integer){
    if ($blackjack-main:games/game[@id = $gameId]/@phase = "deal") then (
        for $playerId in ($blackjack-main:games/game[@id = $gameId]/players/player/@id, "dealer")
            return
                blackjack-main:drawCard($gameId, $playerId)
    )
};


(:~
 : give every player and the dealer two cards
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:dealPhase($gameId as xs:integer){
    if ($blackjack-main:games/game[@id = $gameId]/@phase = "deal") then (
        blackjack-main:handOutOneCardToEach($gameId),
        update:output(web:redirect(concat("/blackjack/", $gameId, "/handOutOneCardToEach"))),
        update:output(web:redirect(concat("/blackjack/", $gameId)))
    )
};


(:~
 : move Turn to next player or to dealer
 : @playerOnTurn $playerId whose turn it is next
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:moveTurn($gameId as xs:integer, $playerOnTurn as xs:string){
    if ($playerOnTurn = $blackjack-main:games/game[@id = $gameId]/@onTurn
        or $blackjack-main:games/game[@id = $gameId]/@onTurn = "noone") then (
       blackjack-main:moveTurnHelper($gameId, $playerOnTurn))
};


(:~
 : move Turn to next player with less than 21 or to dealer
 : @playerOnTurn $playerId whose turn it is next
 : @return model change to move turn to next player
 :)
declare
%updating
function blackjack-main:moveTurnHelper($gameId as xs:integer, $playerOnTurn as xs:string){
        let $newPlayerTurn := if($playerOnTurn = $blackjack-main:games/game[@id = $gameId]/players/player[last()]/@id )
            then "dealer"
            else if ($playerOnTurn = "dealer") then $blackjack-main:games/game[@id = $gameId]/players/player[position() = 1]/@id
                 else $blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerOnTurn]/following-sibling::*[1]/@id
        return ( if ($newPlayerTurn = "dealer" or $blackjack-main:games/game[@id = $gameId]/players/player[@id=$newPlayerTurn]/hand/@sum <= 20)
            then (
                replace value of node $blackjack-main:games/game[@id = $gameId]/@onTurn with $newPlayerTurn,
                if ($newPlayerTurn = "dealer")
                    then
                        let $dealerHandValue := blackjack-main:calculateHandValue($blackjack-main:games/game[@id = $gameId]/dealer/hand)
                        let $firstCard := $blackjack-main:games/game[@id = $gameId]/dealer/hand/card[position() = 1]
                        return (
                            replace node $blackjack-main:games/game[@id = $gameId]/dealer/hand
                                    with <hand sum="{$dealerHandValue}"><card hidden="false">{$firstCard/type}{$firstCard/value}</card>
                                                {$blackjack-main:games/game[@id = $gameId]/dealer/hand/card[position() > 1]}</hand>,
                            update:output(web:redirect(concat("/blackjack/", $gameId, "/dealerTurn"))),
                            update:output(web:redirect(concat("/blackjack/", $gameId))))
                )
                else (blackjack-main:moveTurnHelper($gameId, $newPlayerTurn))
        )
};

(:~
 : dealer Turn
 : @return model change: dealer has drawn cards
 :)
declare
%updating
function blackjack-main:dealerTurn($gameId as xs:integer){
    if ($blackjack-main:games/game[@id = $gameId]/@onTurn = "dealer") then (
    let $dealerHandValue := blackjack-main:calculateHandValue($blackjack-main:games/game[@id = $gameId]/dealer/hand)
    return (
            prof:sleep(2000),(: pause for 1000ms :)
            if ($dealerHandValue < 17)
            then (blackjack-main:drawCard($gameId, "dealer"),
            update:output(web:redirect(concat("/blackjack/", $gameId, "/dealerTurn"))))
            else replace value of node $blackjack-main:games/game[@id = $gameId]/@phase with "pay",
                 update:output(web:redirect(concat("/blackjack/", $gameId, "/pay")))))
};


(:~
 : adding a player to the game
 : @playerId $playerId who will be added
 : @return model change to insert Player to the current game
 :)
declare
%updating
function blackjack-main:addPlayer($gameId as xs:integer, $playerId as xs:string) as empty-sequence(){
    if (exists($blackjack-main:players/player[@id = $playerId])
        and empty($blackjack-main:games/game[@id = $gameId]/players/player[@id = playerId])
        and count($blackjack-main:games/game[@id = $gameId]/players/player) < 4
        and $blackjack-main:games/game[@id = $gameId]/@phase = "bet"
        and $blackjack-main:games/game[@id = $gameId]/@singlePlayer = "false")
        then(
            let $playerName := $blackjack-main:players/player[@id = $playerId]/@name
            let $newPlayer :=
                  <player id="{$playerId}" name="{$playerName}">
                          <hand/>
                          <wallet>500</wallet>
                          <pool locked="false"/>
                   </player>
    return( insert node $newPlayer as last into $blackjack-main:games/game[@id = $gameId]/players,
            update:output(web:redirect(concat("/blackjack/", $gameId, "/join?playerId=", $playerId))))
    )
};


declare function blackjack-main:getGame($gameId as xs:integer){
    $blackjack-main:games/game[@id = $gameId]
};


declare function blackjack-main:getGames(){
    $blackjack-main:games
};


declare function blackjack-main:getPlayers(){
    $blackjack-main:players
};


(:~
 : Inserts player score to high score list and computes new board
 : @playerId ID of the player to be inserted
 : @return New high score board
 :)
declare
%updating
function blackjack-main:addHighscore($gameId as xs:integer, $playerId as xs:string){
    let $playerName := string($blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/@name)
    let $playerScore := $blackjack-main:games/game[@id = $gameId]/players/player[@id=$playerId]/wallet/text()
    let $currentHighscore := $blackjack-main:players/player[@id=$playerId]/@highscore
    let $newEntry :=
    <highscore>
        <name>{$playerName}</name>
        <score>{$playerScore}</score>
    </highscore>
    return (
        if ($playerScore > 0 and $playerScore > $currentHighscore) then (
            (: Replace old highscore value with new highscore in player database :)
            replace value of node $blackjack-main:players/player[@id=$playerId]/@highscore with $playerScore,
            (: Add new highscore to highscore database :)
            insert node $newEntry as last into $blackjack-main:highscores)
        )
};


(:~
 : End game: save all highscores and remove game from lobby
 : @gameId ID of the game to be terminated
 : @return Model change in highscore and lobby database
 :)
declare
%updating
function blackjack-main:endGame($gameId as xs:integer){
    (: TODO: Test method :)
    (: Save scores of all players :)
    for $playerId in $blackjack-main:games/game[@id = $gameId]/players/player/@id
    return blackjack-main:addHighscore($gameId, $playerId),
    (: Remove game from game directory :)
    delete node $blackjack-main:games/game[@id = $gameId]
};
