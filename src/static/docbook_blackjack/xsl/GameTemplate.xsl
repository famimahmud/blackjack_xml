<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xls="http://www.w3.org/1999/XSL/Transform" xmlns:xslt="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes"/>

    <!-- XSLT template parameters -->
    <xsl:param name="gameId"/>
    <xsl:param name="playerId"/>

    <!-- Imports -->
    <xsl:include href="CardTemplate.xsl"/>
    <xsl:include href="ChipTemplate.xsl"/>

    <xsl:template match="/">

        <!-- Variables -->
        <xsl:variable name="width" select="150"/>
        <xsl:variable name="height" select="100"/>
        <xsl:variable name="fieldWidth" select="23"/>
        <xsl:variable name="fieldHeight" select="26"/>
        <xsl:variable name="cardWidth" select="$fieldWidth - 10"/>
        <xsl:variable name="cardHeight" select="18"/>
        <xsl:variable name="chipSize" select="5"/>
        <xsl:variable name="deckX" select="110"/>
        <xsl:variable name="deckY" select="7"/>
        <xsl:variable name="dealerX" select="($width - $fieldWidth) div 2"/>
        <xsl:variable name="dealerY" select="7"/>
        <xsl:variable name="playerY" select="67"/>
        <xsl:variable name="textColor" select="'white'"/>
        <xsl:variable name="onTurnColor" select="'gold'"/>
        <xsl:variable name="strokeWidth" select="0.3"/>
        <xsl:variable name="cornerRadius" select="2"/>
        <xsl:variable name="fontSize" select="4"/>
        <xsl:variable name="strokeColor" select="'white'"/>
        <xsl:variable name="fonts" select="'Raleway, sans-serif'"/>
        <xsl:variable name="playerCount" select="count(game/players/player[not(left)])"/>
        <xsl:variable name="rectHeight" select="5"/>
        <xsl:variable name="rectWidth" select="25"/>
        <xsl:variable name="playerName" select="game/players/player[@id=$playerId]/@name"/>

        <!-- Chip value list for loop -->
        <xsl:variable name="chipValueList">
            <value>10</value>
            <value>50</value>
            <value>100</value>
            <value>250</value>
            <value>500</value>
            <value>1000</value>
        </xsl:variable>
        <xsl:variable name="chipValues" select="document('')//xsl:variable[@name = 'chipValueList']/*"/>

        <!-- Get current player that is on turn -->
        <xsl:variable name="currentPlayer">
            <xsl:if test="/*/@onTurn = 'dealer'">
                the Dealer
            </xsl:if>
            <xsl:for-each select="/*/players/*">
                <xsl:if test="@id = /*/@onTurn">
                    <xsl:value-of select="@name"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>

        <svg id="table" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="100%" height="100%" viewBox="0 0 {$width} {$height}"
             font-family="{$fonts}" font-size="{$fontSize}">

            <!-- Import online fonts -->
            <defs>
                <style type="text/css">@import url('https://fonts.googleapis.com/css?family=Raleway');</style>
            </defs>

            <!-- Information bow in middle of screen, currently disabled
            <text x="{$width div 2}" y="{$height - 4}" stroke="none" text-anchor="middle" alignment-baseline="middle"
                  fill="white">
                <textPath xlink:href="#infoBow" fill="{$textColor}" startOffset="45">-->
                <!--<xsl:value-of select="concat('It''s ', $currentPlayer, '''s turn!')"/>-->
                <!--</textPath>
            </text> -->

            <!-- Generate card deck -->
            <!-- Print Deck Box -->
            <rect x="{$deckX}" y="{$deckY}" width="{$cardWidth}" height="{$cardHeight}" rx="{$cornerRadius}"
                  ry="{$cornerRadius}" fill="none" stroke="{$strokeColor}" stroke-width="{$strokeWidth}"/>
            <!-- Print Cards -->
            <xsl:for-each select="*/deck/*">
                <svg width="{$cardWidth}" height="{$cardHeight}"
                     x="{$deckX + 1.6}"
                     y="{$deckY}" viewBox="0 0 5 7">
                    <!-- Call card template -->
                    <xsl:call-template name="CardTemplate">
                        <xsl:with-param name="cardType" select="type"/>
                        <xsl:with-param name="cardValue" select="value"/>
                        <xsl:with-param name="id" select="-position()"/>
                    </xsl:call-template>
                </svg>
            </xsl:for-each>

            <!-- Game and player information in the top left corner -->
            <rect class="infoBox" x="0" y="0" rx="2" ry="2" height="15" width="30"/>
            <text x="2" y="2" fill="{$textColor}" font-size="{$fontSize - 1.5}" text-decoration="underline"
                  font-family="{$fonts}"
                  alignment-baseline="hanging">
                <!-- Show game ID -->
                <xsl:value-of select="concat('Game#', $gameId)"/>
            </text>

            <text x="2" y="6" fill="{$textColor}" font-size="{$fontSize - 1.5}"
                  font-family="{$fonts}"
                  alignment-baseline="hanging">
                <!-- Show player name -->
                <xsl:value-of select="concat('Name: ', $playerName)"/>
            </text>
            <text x="2" y="10" fill="{$textColor}" font-size="{$fontSize - 1.5}"
                  font-family="{$fonts}"
                  alignment-baseline="hanging">
                <!-- Show player ID -->
                <xsl:value-of select="concat('ID: ', $playerId)"/>
            </text>

            <!-- Generate Dealer card box -->
            <symbol id="dealerBox">
                <!-- Choose box color -->
                <xsl:variable name="color">
                    <xsl:choose>
                        <xsl:when test="(/*/@onTurn = 'dealer') and (/*/@phase = 'play')">
                            <xsl:value-of select="$onTurnColor"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$textColor"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- Generate dealer box -->
                <text x="{$fieldWidth div 2}" y="{$dealerY - 4}" text-anchor="middle"
                      alignment-baseline="central"
                      fill="{$color}" stroke="none">
                    Dealer
                </text>
                <rect y="{$dealerY}" width="{$fieldWidth}" height="{$cardHeight}" rx="{$cornerRadius}"
                      ry="{$cornerRadius}" stroke="{$color}" fill="none" stroke-width="{$strokeWidth}"/>

                <!-- Add cards -->
                <xsl:for-each select="*/dealer/hand/*">
                    <svg width="{$cardWidth}" height="{$cardHeight}"
                         x="{((position()) div (count(parent::hand/*) + 1)) * ($fieldWidth - 5) - (0.5 * 5)}"
                         y="{$dealerY}" viewBox="0 0 5 7">
                        <xsl:call-template name="CardTemplate">
                            <xsl:with-param name="cardType" select="type"/>
                            <xsl:with-param name="cardValue" select="value"/>
                            <xsl:with-param name="id" select="-position()"/>
                        </xsl:call-template>
                    </svg>
                </xsl:for-each>

                <!-- Show dealer hand sum -->
                <xsl:variable name="handSum" select="*/dealer/hand/@sum"/>

                <xsl:if test="$handSum > 0">
                    <!-- Choose sum color depending on hand value -->
                    <xsl:variable name="counterBackground">
                        <xsl:choose>
                            <xsl:when test="$handSum > 21">red</xsl:when>
                            <xsl:when test="$handSum = 21">goldenrod</xsl:when>
                            <xsl:otherwise>#134900</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <svg width="4" height="3" x="{$fieldWidth - 5}" y="8">
                        <rect x="0" y="0" rx="0.75" ry="0.75" width="100%" height="100%"
                              style="fill: {$counterBackground}; opacity:0.75"/>
                        <text x="2" y="1.5" fill="white" text-anchor="middle"
                              alignment-baseline="central" font-size="2.5">
                            <!-- Show calculated sum -->
                            <xsl:value-of select="$handSum"/>
                        </text>
                    </svg>
                </xsl:if>
            </symbol>

            <!-- Print dealer box -->
            <use xlink:href="#dealerBox" x="{$dealerX}" y="{$dealerY}"/>

            <!-- Generate player card boxes for each player still in game -->
            <xsl:for-each select="*/players/player[not(left)]">
                <xsl:variable name="name" select="@name"/>
                <xsl:variable name="locked" select="pool/@locked"/>
                <xsl:variable name="wallet" select="wallet"/>
                <xsl:variable name="position" select="position()"/>
                <xsl:variable name="fieldPos"
                              select="(($width * ($position div ($playerCount + 1))) - ($fieldWidth div 2))"/>
                <xsl:variable name="playerColor">
                    <!-- Color player's box gold it on turn -->
                    <xsl:choose>
                        <xsl:when test="@id = /*/@onTurn">
                            <xsl:value-of select="$onTurnColor"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$textColor"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <symbol id="playerBox{$position}" overflow="visible">
                    <rect width="{$fieldWidth}" height="{$fieldHeight}" rx="{$cornerRadius}"
                          ry="{$cornerRadius}" stroke="{$playerColor}" fill="none" stroke-width="{$strokeWidth}"/>
                    <text x="{$fieldWidth div 2}" y="{$fieldHeight + ($fontSize div 2) + 1}" text-anchor="middle"
                          alignment-baseline="central"
                          fill="{$playerColor}" stroke="none">
                        <xsl:choose>
                            <xsl:when test="/*/@phase ='bet' and $locked = 'true'">
                                <xsl:value-of select="concat($name, ' ✓')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$name"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </text>
                    <text x="{$fieldWidth div 2}" y="{$fieldHeight + ($fontSize div 2) + 4}" text-anchor="middle"
                          alignment-baseline="central" font-size="2"
                          fill="{$playerColor}" stroke="none">
                        <xsl:value-of select="concat($wallet, ' $')"/>
                    </text>

                    <line x1="0" x2="{$fieldWidth}" y1="6" y2="6" stroke="{$playerColor}"
                          stroke-width="{$strokeWidth}"/>

                    <!-- Show bet count -->
                    <text x="{$fieldWidth div 2}" y="{-2}" text-anchor="middle"
                          alignment-baseline="central"
                          fill="{$playerColor}" stroke="none" font-size="2">
                        <xsl:value-of select="concat('Bet: ', sum(pool/chip/value), ' $')"/>
                    </text>

                    <!-- Insert chips -->
                    <xsl:for-each select="pool/*">

                        <xsl:if test="count(*) != 0">
                            <svg width="{$chipSize}" height="{$chipSize}"
                                 x="{((position()) div (count(parent::pool/*) + 1)) * ($fieldWidth) - (0.5 * $chipSize)}"
                                 y="0.5">
                                <xsl:call-template name="ChipTemplate">
                                    <xsl:with-param name="chipValue" select="value"/>
                                    <xsl:with-param name="id" select="concat($position, position())"/>
                                </xsl:call-template>
                            </svg>
                        </xsl:if>
                    </xsl:for-each>

                    <!-- Insert cards -->
                    <xsl:for-each select="hand/*">
                        <svg width="{$cardWidth}" height="{$cardHeight}"
                             x="{((position()) div (count(parent::hand/*) + 1)) * ($fieldWidth - 5) - (0.5 * 5)}"
                             y="7" viewBox="0 0 5 7">
                            <xsl:call-template name="CardTemplate">
                                <xsl:with-param name="cardType" select="type"/>
                                <xsl:with-param name="cardValue" select="value"/>
                                <xsl:with-param name="id" select="concat($position, position())"/>
                            </xsl:call-template>
                        </svg>
                    </xsl:for-each>

                    <!-- Get calculated hand sum -->
                    <xsl:variable name="handSum" select="hand/@sum"/>

                    <!-- Show hand some information field -->
                    <xsl:if test="$handSum > 0">
                        <xsl:variable name="counterBackground">
                            <!-- Choose color depending on hand value -->
                            <xsl:choose>
                                <xsl:when test="$handSum > 21">red</xsl:when>
                                <xsl:when test="$handSum = 21">goldenrod</xsl:when>
                                <xsl:otherwise>#134900</xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <!-- Insert information box -->
                        <svg width="4" height="3" x="{$fieldWidth - 5}" y="7">
                            <rect x="0" y="0" rx="0.75" ry="0.75" width="100%" height="100%"
                                  style="fill: {$counterBackground}; opacity:0.75"/>
                            <text x="2" y="1.5" fill="white" text-anchor="middle"
                                  alignment-baseline="central" font-size="2.5">
                                <xsl:value-of select="$handSum"/>
                            </text>
                        </svg>
                    </xsl:if>
                </symbol>

                <!-- Curve player box depending on total player count and position -->
                <!-- Curve function: 10 * (count - 2*pos + 1) / (count - 1) -->
                <xsl:variable name="curveFactor">
                    <xsl:choose>
                        <xsl:when test="$playerCount = 1">0</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="10 * ($playerCount - 2*$position + 1) div ($playerCount - 1)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- Get shift of box depending on total player count and position -->
                <!-- Shift function: 10 * (pos - count + (count - 1) / 2) -->
                <xsl:variable name="shiftFactor"
                              select="7 div $playerCount * ($position - $playerCount + ($playerCount - 1) div 2) * ($position - $playerCount + ($playerCount - 1) div 2)"/>

                <!-- Render player box -->
                <use xlink:href="#playerBox{$position}" x="{$fieldPos - ($curveFactor * 2)}"
                     y="{$playerY - $shiftFactor - 10}"
                     transform="rotate({$curveFactor} {$fieldPos + $fieldWidth div 2} {$playerY + $fieldHeight div 2})"/>
            </xsl:for-each>

            <!--Show exit Button-->
            <foreignObject width="20%" height="10%" x="90%" y="0%">
                <form xmlns="http://www.w3.org/1999/xhtml" action="/docbook_blackjack/{$gameId}/exit" method="post" id="Exit">
                    <button class="gameButton" form="Exit" value="Submit">
                        Exit
                    </button>
                    <input type="hidden" name="playerId" id="playerIdExit" value="{$playerId}"/>
                    <input type="hidden" name="playerName" id="playerNameExit" value="{$playerName}"/>
                </form>
            </foreignObject>

            <!--New Round Button for result phase-->
            <xsl:choose>
                <xsl:when test="/game/@phase = 'pay' and game/players/player[@id = $playerId]">
                    <foreignObject width="15%" height="20%" x="90%" y="10%">
                        <form xmlns="http://www.w3.org/1999/xhtml" action="/docbook_blackjack/{$gameId}/pay" method="get" id="newRound" target="hiddenFrame">
                            <button class="gameButton" form="newRound" value="Submit">
                                Continue
                            </button>
                            <input type="hidden" name="playerId" id="playerIdNewRound" value="{$playerId}"/>
                            <input type="hidden" name="playerName" id="playerNameNewRound" value="{$playerName}"/>
                        </form>
                    </foreignObject>
                </xsl:when>
            </xsl:choose>

            <!--Bet Buttons or Hit & Stand-->
            <xsl:choose>
                <!-- Player has yet to bet and has not confirmed yet: Show confirm and reset buttons -->
                <xsl:when test="/*/@phase ='bet' and game/players/player[@id = $playerId]/pool/@locked = 'false' and count(game/players/player[@id = $playerId]/pool/*) != 0">
                    <foreignObject width="100%" height="100%" x="0%" y="93%">
                        <form xmlns="http://www.w3.org/1999/xhtml" action="/docbook_blackjack/{$gameId}/confirmBet"
                              method="post"
                              id="Confirm" target="hiddenFrame">
                            <button class="gameButton" form="Confirm" value="Submit">
                                Confirm
                            </button>
                            <input type="hidden" name="playerId" id="playerIdConfirm" value="{$playerId}"/>
                        </form>
                    </foreignObject>
                    <foreignObject width="100%" height="100%" x="90%" y="93%">
                        <form xmlns="http://www.w3.org/1999/xhtml" action="/docbook_blackjack/{$gameId}/resetBet" method="post"
                              id="Reset" target="hiddenFrame">
                            <button class="gameButton" form="Reset" value="Submit">
                                Reset
                            </button>
                            <input type="hidden" name="playerId" id="playerIdReset" value="{$playerId}"/>
                        </form>
                    </foreignObject>
                </xsl:when>
                <!-- Player in play phase: show hit and stand buttons -->
                <xsl:when test="( /*/@phase ='play') and (/*/@onTurn = $playerId)">
                    <foreignObject width="100%" height="100%" x="0%" y="93%">
                        <form xmlns="http://www.w3.org/1999/xhtml" action="/docbook_blackjack/{$gameId}/hit" method="post"
                              id="Hit" target="hiddenFrame">
                            <button class="gameButton" form="Hit" value="Submit">
                                Hit
                            </button>
                            <input type="hidden" name="playerId" id="playerIdHit" value="{$playerId}"/>
                        </form>
                    </foreignObject>
                    <foreignObject width="100%" height="100%" x="90%" y="93%">
                        <form xmlns="http://www.w3.org/1999/xhtml" action="/docbook_blackjack/{$gameId}/stand" method="post"
                              id="Stand" target="hiddenFrame">
                            <button class="gameButton" form="Stand" value="Submit">
                                Stand
                            </button>
                            <input type="hidden" name="playerId" id="playerIdStand" value="{$playerId}"/>
                        </form>
                    </foreignObject>
                </xsl:when>
            </xsl:choose>

            <!--Use chips as Buttons-->
            <xsl:for-each select="$chipValues">
                <xsl:variable name="index" select="position()"/>
                <xsl:variable name="value" select="."/>

                <foreignObject width="7" height="7" x="{25 + 9 * ($index - 1)}%" y="93%">
                    <form xmlns="http://www.w3.org/1999/xhtml" action="/docbook_blackjack/{$gameId}/bet" method="post" id="Chip_{$value}" target="hiddenFrame">
                        <label>
                            <svg width="7" height="7">
                                <xsl:call-template name="ChipTemplate">
                                    <xsl:with-param name="chipValue" select="$value"/>
                                    <xsl:with-param name="id" select="$value"/>
                                </xsl:call-template>
                            </svg>
                            <input class="chipButton" type="submit" name="chipValue" id="value{$value}" value="{$value}"/>
                            <input type="hidden" name="playerId" id="playerId{$playerId}" value="{$playerId}"/>
                        </label>
                    </form>
                </foreignObject>
            </xsl:for-each>

            <!-- Invisible iframe to throw away results of POST request -->
            <foreignObject width="0" height="0">
                <iframe class = "hiddenFrame" xmlns = "http://www.w3.org/1999/xhtml" name="hiddenFrame"/>
            </foreignObject>
        </svg>

    </xsl:template>

</xsl:stylesheet>
