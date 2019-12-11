xquery version "3.0";

module namespace blackjack-controller = "blackjack-controller.xqm";
import module namespace blackjack-main = "Blackjack/Main" at "blackjack-main.xqm";

declare variable $blackjack-controller:staticPath := "../static/blackjack";

declare
%rest:path("blackjack/setup")
%output:method("xhtml")
%updating
%rest:GET
function blackjack-controller:setup() {
    let $model := doc("../static/blackjack/Game.xml")
    let $redirectLink := "/blackjack/start"
    return (db:create("Game", $model), update:output(web:redirect($redirectLink)))
};

declare
%rest:GET
%output:method("html")
%rest:path("/blackjack/start")
function blackjack-controller:lobby(){
    let $game := blackjack-main:getGame()
        let $xslStylesheet := "GameTemplate.xsl"
        let $title := "Blackjack"
        return (blackjack-controller:genereratePage($game, $xslStylesheet, $title))
};

declare
%rest:path("/blackjack/newRound")
%rest:POST
%updating
function blackjack-controller:newRound(){
    let $redirectLink := "/blackjack/draw"
    return (blackjack-main:newRound(), update:output(web:redirect("/blackjack/draw")))
};

declare
%rest:path("/blackjack/draw")
%output:method("html")
%rest:GET
function blackjack-controller:drawGame(){
    let $game := blackjack-main:getGame()
    let $xslStylesheet := "GameTemplate.xsl"
    let $title := "Blackjack"
    return (blackjack-controller:genereratePage($game, $xslStylesheet, $title))
};

declare function blackjack-controller:genereratePage($game as element(game), $xslStylesheet as xs:string,
        $title as xs:string) {
    let $stylesheet := doc(concat($blackjack-controller:staticPath, "/XSL/", $xslStylesheet))
    let $transformed := xslt:transform($game, $stylesheet)
    return
        <html>
            <head>
                <title>{$title}</title>
            </head>
            <body>
                {$transformed}
            </body>
        </html>
};
