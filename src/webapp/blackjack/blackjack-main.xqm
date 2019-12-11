xquery version "3.0";

module namespace blackjack-main = "Blackjack/Main";
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
function blackjack-main:newRound() { (:$player as element(player)) {:)
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
                $player
            </players>
        </game>

    return (replace node $blackjack-main:game with $game)
};

declare function blackjack-main:getGame(){
    $blackjack-main:game
};
