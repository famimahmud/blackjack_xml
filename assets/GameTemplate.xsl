<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xls="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes"/>

    <!-- Imports -->
    <xsl:include href="Cards/CardTemplate.xsl"/>

    <xsl:template match="/">

        <!-- Variables -->
        <xsl:variable name="width" select="150"/>
        <xsl:variable name="height" select="100"/>
        <xsl:variable name="fieldWidth" select="20"/>
        <xsl:variable name="fieldHeight" select="15"/>
        <xsl:variable name="deckX" select="110"/>
        <xsl:variable name="deckY" select="7"/>
        <xsl:variable name="dealerY" select="5"/>
        <xsl:variable name="playerY" select="65"/>
        <xsl:variable name="textColor" select="'white'"/>
        <xsl:variable name="onTurnColor" select="'gold'"/>
        <xsl:variable name="strokeWidth" select="0.3"/>
        <xsl:variable name="cornerRadius" select="2"/>
        <xsl:variable name="fieldRotation" select="10"/>
        <xsl:variable name="fontSize" select="4"/>
        <xsl:variable name="playerCount" select="count(/*/players/*)"/>

        <xsl:variable name="cardHeight" select="7"/>
        <xsl:variable name="edgeRadius" select="0.25"/>


        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="100%" height="100%" viewBox="0 0 {$width} {$height}"
             font-family="serif" font-size="{$fontSize}"
             style="background: url(TableBackground.svg); background-size: 100% 100%">

            <path id="infoBow" d="M30 40  Q75 50, 120 40" stroke-width="{$strokeWidth}" fill="none"/>
            <path d="M30 50 Q75 60, 120 50" stroke-width="{$strokeWidth}" fill="none"/>
            <path d="M30 40 L30 50" stroke-width="{$strokeWidth}"/>
            <path d="M120 40 L120 50" stroke-width="{$strokeWidth}"/>

            <text dy="-4" stroke="none" text-anchor="middle" alignment-baseline="central">
                <textPath xlink:href="#infoBow" fill="{$textColor}" startOffset="45">It's Alice's turn!</textPath>
            </text>

            <rect x="{$deckX}" y="{$deckY}" width="{$fieldWidth div 2}" height="{$fieldHeight}" rx="{$cornerRadius}"
                  ry="{$cornerRadius}" fill="none" stroke-width="{$strokeWidth}"/>

            <xsl:variable name="color">
                <xsl:choose>
                    <xsl:when test="/*/dealer/@turn = 'true'">
                        <xsl:value-of select="$onTurnColor"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$textColor"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <svg x="{($width - $fieldWidth) div 2}" y="{$dealerY}">
                <text x="{$fieldWidth div 2}" y="{$fontSize div 2}" text-anchor="middle" alignment-baseline="central"
                      fill="{$color}" stroke="none">
                    Dealer
                </text>
                <rect y="{$fieldHeight div 3}" width="{$fieldWidth}" height="{$fieldHeight}" rx="{$cornerRadius}"
                      ry="{$cornerRadius}" stroke="{$color}" fill="none" stroke-width="{$strokeWidth}"/>
            </svg>

            <xsl:for-each select="*/players/player">
                <xsl:variable name="name" select="@name"/>
                <xsl:variable name="position" select="position()"/>
                <xsl:variable name="fieldPos"
                              select="(($width * ($position div ($playerCount + 1))) - ($fieldWidth div 2))"/>
                <xsl:variable name="playerColor">
                    <xsl:choose>
                        <xsl:when test="@turn = 'true'">
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
                    <text x="{$fieldWidth div 2}" y="{$fieldHeight + ($fontSize div 2)}" text-anchor="middle"
                          alignment-baseline="central"
                          fill="{$playerColor}" stroke="none">
                        <xsl:value-of select="$name"/>
                    </text>

                    <xsl:for-each select="hand/*">
                        <svg width="10" height="14" x="{1.5 + ((position() - 1) * 10)}" y="0" viewBox="0 0 5 7">
                            <xsl:call-template name="CardTemplate">
                                <xsl:with-param name="cardType" select="type"/>
                                <xsl:with-param name="cardValue" select="value"/>
                                <xsl:with-param name="id" select="$position + position()"/>
                            </xsl:call-template>
                        </svg>

                    </xsl:for-each>
                </symbol>

                <!--
                <xsl:choose>
                    <xsl:when test="($playerCount) > 1 and $position = 1">
                        <use xlink:href="#playerBox{$position}" x="{$fieldPos}" y="{$playerY}" transform="rotate({$fieldRotation},{$fieldPos + $fieldWidth}, {$playerY})"/>
                    </xsl:when>
                    <xsl:when test="($playerCount) > 1 and $position = $playerCount">
                        <use xlink:href="#playerBox{$position}" x="{$fieldPos}" y="{$playerY}" transform="rotate({$fieldRotation * -1},{$fieldPos}, {$playerY})"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <use xlink:href="#playerBox{$position}" x="{$fieldPos}" y="{$playerY}"/>
                    </xsl:otherwise>
                </xsl:choose>
                -->

                <!-- Curve function: 10 * (count - 2*pos + 1) / (count - 1) -->
                <xsl:variable name="curveFactor" select="10 * ($playerCount - 2*$position + 1) div ($playerCount - 1)"/>
                <!-- Shift function: 10 * (pos - count + (count - 1) / 2) -->
                <xsl:variable name="shiftFactor"
                              select="7 div $playerCount * ($position - $playerCount + ($playerCount - 1) div 2) * ($position - $playerCount + ($playerCount - 1) div 2)"/>
                <use xlink:href="#playerBox{$position}" x="{$fieldPos}" y="{$playerY - $shiftFactor}"
                     transform="rotate({$curveFactor} {$fieldPos + $fieldWidth div 2} {$playerY + $fieldHeight div 2})"/>
            </xsl:for-each>
        </svg>

    </xsl:template>

</xsl:stylesheet>
