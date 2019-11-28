<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xls="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes"/>

    <!-- Imports -->
    <xsl:include href="Cards/CardTemplate.xsl"/>
    <xsl:include href="Chips/ChipTemplate.xsl"/>

    <xsl:template match="/">

        <!-- Variables -->
        <xsl:variable name="width" select="150"/>
        <xsl:variable name="height" select="100"/>
        <xsl:variable name="fieldWidth" select="23"/>
        <xsl:variable name="fieldHeight" select="18"/>
        <xsl:variable name="cardWidth" select="$fieldWidth - 10"/>
        <xsl:variable name="cardHeight" select="$fieldHeight"/>
        <xsl:variable name="deckX" select="110"/>
        <xsl:variable name="deckY" select="7"/>
        <xsl:variable name="dealerX" select="($width - $fieldWidth) div 2"/>
        <xsl:variable name="dealerY" select="5"/>
        <xsl:variable name="playerY" select="67"/>
        <xsl:variable name="textColor" select="'white'"/>
        <xsl:variable name="onTurnColor" select="'gold'"/>
        <xsl:variable name="strokeWidth" select="0.3"/>
        <xsl:variable name="cornerRadius" select="2"/>
        <xsl:variable name="fontSize" select="4"/>
        <xsl:variable name="strokeColor" select="'white'"/>
        <xsl:variable name="fonts" select="'Playfair Display, serif'"/>
        <xsl:variable name="playerCount" select="count(/*/players/*)"/>

        <xsl:variable name="currentPlayer">
            <xsl:if test="/*/dealer/@onTurn = 'true'">
                the Dealer
            </xsl:if>
            <xsl:for-each select="/*/players/*">
                <xsl:if test="@onTurn = 'true'">
                    <xsl:value-of select="@name"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>

        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="100%" height="100%" viewBox="0 0 {$width} {$height}"
             font-family="{$fonts}" font-size="{$fontSize}"
             style="background: url(TableBackground.svg); background-size: 100% 100%">

            <!-- Import online fonts -->
            <defs>
                <style type="text/css">@import url('https://fonts.googleapis.com/css?family=Playfair+Display');</style>
            </defs>

            <path id="infoBow" d="M30 40  Q75 50, 120 40" stroke="{$strokeColor}" stroke-width="{$strokeWidth}"
                  fill="none"/>
            <path d="M30 50 Q75 60, 120 50" stroke="{$strokeColor}" stroke-width="{$strokeWidth}" fill="none"/>
            <path d="M30 40 L30 50" stroke="{$strokeColor}" stroke-width="{$strokeWidth}"/>
            <path d="M120 40 L120 50" stroke="{$strokeColor}" stroke-width="{$strokeWidth}"/>

            <text dy="-4" stroke="none" text-anchor="middle" alignment-baseline="central">
                <textPath xlink:href="#infoBow" fill="{$textColor}" startOffset="45">
                    <xsl:value-of select="concat('It''s ', $currentPlayer, '''s turn!')"/>
                </textPath>
            </text>

            <!-- Generate card deck -->
            <rect x="{$deckX}" y="{$deckY}" width="{$fieldWidth div 2}" height="{$fieldHeight}" rx="{$cornerRadius}"
                  ry="{$cornerRadius}" fill="none" stroke="{$strokeColor}" stroke-width="{$strokeWidth}"/>

            <!-- Generate Dealer card box -->
            <!-- Choose box color -->
            <symbol id="dealerBox">
                <xsl:variable name="color">
                    <xsl:choose>
                        <xsl:when test="/*/dealer/@onTurn = 'true'">
                            <xsl:value-of select="$onTurnColor"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$textColor"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- Generate box -->
                <text x="{$fieldWidth div 2}" y="{$fontSize div 2}" text-anchor="middle"
                      alignment-baseline="central"
                      fill="{$color}" stroke="none">
                    Dealer
                </text>
                <rect y="{$fieldHeight div 3}" width="{$fieldWidth}" height="{$fieldHeight}" rx="{$cornerRadius}"
                      ry="{$cornerRadius}" stroke="{$color}" fill="none" stroke-width="{$strokeWidth}"/>

                <!-- Add cards -->
                <xsl:for-each select="*/dealer/hand/*">
                    <svg width="{$cardWidth}" height="{$cardHeight}"
                         x="{(position() div count(parent::hand/*)) * ($fieldWidth - $cardWidth - (1.5 div position()))}"
                         y="{$dealerY + 1}" viewBox="0 0 5 7">
                        <xsl:call-template name="CardTemplate">
                            <xsl:with-param name="cardType" select="type"/>
                            <xsl:with-param name="cardValue" select="value"/>
                            <xsl:with-param name="id" select="-position()"/>
                        </xsl:call-template>
                    </svg>
                </xsl:for-each>
            </symbol>
            <use xlink:href="#dealerBox" x="{$dealerX}" y="{$dealerY}"/>

            <!-- Generate player card boxes -->
            <xsl:for-each select="*/players/player">
                <xsl:variable name="name" select="@name"/>
                <xsl:variable name="position" select="position()"/>
                <xsl:variable name="fieldPos"
                              select="(($width * ($position div ($playerCount + 1))) - ($fieldWidth div 2))"/>
                <xsl:variable name="playerColor">
                    <xsl:choose>
                        <xsl:when test="@onTurn = 'true'">
                            <xsl:value-of select="$onTurnColor"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$textColor"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <symbol id="playerBox{$position}">
                    <rect width="{$fieldWidth}" height="{$fieldHeight}" rx="{$cornerRadius}"
                          ry="{$cornerRadius}" stroke="{$playerColor}" fill="none" stroke-width="{$strokeWidth}"/>
                    <text x="{$fieldWidth div 2}" y="{$fieldHeight + ($fontSize div 2) + 1}" text-anchor="middle"
                          alignment-baseline="central"
                          fill="{$playerColor}" stroke="none">
                        <xsl:value-of select="$name"/>
                    </text>

                    <xsl:for-each select="hand/*">
                        <svg width="{$cardWidth}" height="{$cardHeight}"
                             x="{((position()) div count(parent::hand/*)) * ($fieldWidth - $cardWidth - (1.5 div position()))}"
                             y="0" viewBox="0 0 5 7">
                            <xsl:call-template name="CardTemplate">
                                <xsl:with-param name="cardType" select="type"/>
                                <xsl:with-param name="cardValue" select="value"/>
                                <xsl:with-param name="id" select="$position + position()"/>
                            </xsl:call-template>
                        </svg>
                    </xsl:for-each>
                </symbol>

                <!-- Curve function: 10 * (count - 2*pos + 1) / (count - 1) -->
                <xsl:variable name="curveFactor" select="10 * ($playerCount - 2*$position + 1) div ($playerCount - 1)"/>
                <!-- Shift function: 10 * (pos - count + (count - 1) / 2) -->
                <xsl:variable name="shiftFactor"
                              select="7 div $playerCount * ($position - $playerCount + ($playerCount - 1) div 2) * ($position - $playerCount + ($playerCount - 1) div 2)"/>

                <!-- Render player box -->
                <use xlink:href="#playerBox{$position}" x="{$fieldPos - ($curveFactor * 2)}"
                     y="{$playerY - $shiftFactor}"
                     transform="rotate({$curveFactor} {$fieldPos + $fieldWidth div 2} {$playerY + $fieldHeight div 2})"/>
            </xsl:for-each>
        </svg>

    </xsl:template>

</xsl:stylesheet>
