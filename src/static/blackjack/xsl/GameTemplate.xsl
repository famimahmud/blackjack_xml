<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xls="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes"/>

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
        <xsl:variable name="playerCount" select="count(/*/players/*)"/>

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

        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="100%" height="100%" viewBox="0 0 {$width} {$height}"
             font-family="{$fonts}" font-size="{$fontSize}"
             style="background-size: 100% 100%">

            <!-- Import online fonts -->
            <defs>
                <style type="text/css">@import url('https://fonts.googleapis.com/css?family=Raleway');</style>
            </defs>

            <text x="{$width div 2}" y="{$height - 4}" stroke="none" text-anchor="middle" alignment-baseline="middle"
                  fill="white">
                <!--<textPath xlink:href="#infoBow" fill="{$textColor}" startOffset="45">-->
                <!--<xsl:value-of select="concat('It''s ', $currentPlayer, '''s turn!')"/>-->
                <!--</textPath>-->
            </text>

            <!-- Generate card deck -->
            <!-- Print Box -->
            <rect x="{$deckX}" y="{$deckY}" width="{$cardWidth}" height="{$cardHeight}" rx="{$cornerRadius}"
                  ry="{$cornerRadius}" fill="none" stroke="{$strokeColor}" stroke-width="{$strokeWidth}"/>
            <!-- Print Cards -->
            <xsl:for-each select="*/deck/*">
                <svg width="{$cardWidth}" height="{$cardHeight}"
                     x="{$deckX + 1.6}"
                     y="{$deckY}" viewBox="0 0 5 7">
                    <xsl:call-template name="CardTemplate">
                        <xsl:with-param name="cardType" select="type"/>
                        <xsl:with-param name="cardValue" select="value"/>
                        <xsl:with-param name="id" select="-position()"/>
                    </xsl:call-template>
                </svg>
            </xsl:for-each>

            <!-- Generate Dealer card box -->
            <!-- Choose box color -->
            <symbol id="dealerBox">
                <xsl:variable name="color">
                    <xsl:choose>
                        <xsl:when test="/*/@onTurn = 'dealer'">
                            <xsl:value-of select="$onTurnColor"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$textColor"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- Generate box -->
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
            </symbol>
            <!-- Print box -->
            <use xlink:href="#dealerBox" x="{$dealerX}" y="{$dealerY}"/>

            <!-- Generate player card boxes -->
            <xsl:for-each select="*/players/player">
                <xsl:variable name="name" select="@name"/>
                <xsl:variable name="wallet" select="wallet"/>
                <xsl:variable name="position" select="position()"/>
                <xsl:variable name="fieldPos"
                              select="(($width * ($position div ($playerCount + 1))) - ($fieldWidth div 2))"/>
                <xsl:variable name="playerColor">
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
                        <xsl:value-of select="$name"/>
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
                                <!-- x="{((position()) div count(parent::pool/*)) * ($fieldWidth - $chipSize) - (0.5 * $chipSize)}" -->
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
                </symbol>

                <!-- Curve function: 10 * (count - 2*pos + 1) / (count - 1) -->
                <xsl:variable name="curveFactor">
                    <xsl:choose>
                        <xsl:when test="$playerCount = 1">0</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="10 * ($playerCount - 2*$position + 1) div ($playerCount - 1)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- Shift function: 10 * (pos - count + (count - 1) / 2) -->
                <xsl:variable name="shiftFactor"
                              select="7 div $playerCount * ($position - $playerCount + ($playerCount - 1) div 2) * ($position - $playerCount + ($playerCount - 1) div 2)"/>

                <!-- Render player box -->
                <use xlink:href="#playerBox{$position}" x="{$fieldPos - ($curveFactor * 2)}"
                     y="{$playerY - $shiftFactor - 10}"
                     transform="rotate({$curveFactor} {$fieldPos + $fieldWidth div 2} {$playerY + $fieldHeight div 2})"/>
            </xsl:for-each>

            <foreignObject width="100%" height="100%" x="90%" y="0%">
                <form xmlns="http://www.w3.org/1999/xhtml" action="/blackjack/start" method="get" id="Exit">
                    <button style=" display:table-cell; font-size:3px; color: white; border-radius:1px; border: none; vertical-align: middle; background-color: #ed4a29 ; cursor: pointer; position: absolute;"
                            form="Exit" value="Submit">
                        Exit
                    </button>
                </form>
            </foreignObject>
        </svg>

    </xsl:template>

</xsl:stylesheet>
