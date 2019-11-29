<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes"/>

    <xsl:template match="/">
        <xsl:variable name="width" select="150"/>
        <xsl:variable name="height" select="100"/>
        <xsl:variable name="fontSize" select="5"/>
        <xsl:variable name="textColor" select="'black'"/>
        <xsl:variable name="startX" select="5"/>
        <xsl:variable name="startY" select="5"/>
        <xsl:variable name="rect2X" select="50"/>
        <xsl:variable name="rect3X" select="105"/>
        <xsl:variable name="rectY" select="30"/>
        <xsl:variable name="rectWidth" select="40"/>
        <xsl:variable name="rectHeight" select="60"/>
        <xsl:variable name="rectMidWidth" select="50"/>
        <xsl:variable name="strokeWidth" select="0.5"/>
        <xsl:variable name="edgeRadius" select="2"/>
        <xsl:variable name="highscoreBoard" select="document('HighscoreBoard.xml')"/>


        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="100%" height="100%" viewBox="0 0 {$width} {$height}"
             style="background: url(LobbyBackground.svg); background-size: 100% 100%">
            <!-- Überschrift -->
            <image x="{($width div 2)-35}" y="{$height div 20}" width="{$fontSize*3}" height="{$fontSize*4}"
                   xlink:href="../Logo.svg"/>
            <text x="{$width div 2}" y="{$height div 10}" fill="{$textColor}" font-size="{$fontSize * 2}"
                  font-family="helvetica" text-anchor="middle"
                  alignment-baseline="hanging">
                Blackjack
            </text>

            <!-- 1. Rechteck - Spiele -->
            <svg x="{$startX}" y="{$rectY}" width="{$rectWidth}" height="{$rectHeight}"
                 viewBox="0 0 {$rectWidth} {$rectHeight}">
                <rect x="0" y="0" width="{$rectWidth}" height="{$rectHeight}" fill="none" rx="{$edgeRadius}"
                      ry="{$edgeRadius}"
                      style="stroke:{$textColor};stroke-width:1"/>
                <!-- Button für neues Spiel-->
                <rect x="{$startX}" y="{$startY}" width="{$rectWidth - 10}" height="{$rectHeight div 6}" fill="none"
                      style="stroke:{$textColor} ;stroke-width:{$strokeWidth}"/>
                <text x="{$rectWidth div 2}" y="{$startY + 2.5}" fill="{$textColor}" font-size="{$fontSize}"
                      font-family="helvetica" text-anchor="middle"
                      alignment-baseline="hanging">
                    Neues Spiel
                </text>
                <!-- Einzelspiel Abfrage -->
                <rect x="{$startX}" y="{$startY + 13}" width="{$rectWidth - 35}" height="{$rectHeight div 12}"
                      fill="none" style="stroke:{$textColor} ;stroke-width:{$strokeWidth}"/>
                <text x="{$startX + 1}" y="{$startY + 14}" font-size="{$fontSize}" alignment-baseline="hanging"
                      fill="{$textColor}">√
                </text>
                <text x="{$startX + 8}" y="{$startY + 14}" font-size="{$fontSize - 1}" alignment-baseline="hanging"
                      fill="{$textColor}">Single-Player?
                </text>

                <!-- Liste der Spiele -->
                <text x="{$startX}" y="{$startY + 22}" font-size="{$fontSize}" alignment-baseline="hanging"
                      fill="{$textColor}">Spiele:
                </text>
                <line x1="{$startX}" y1="{$startY + 27}" x2="{$startX + 14}" y2="{$startY + 27}" fill="{$textColor}"
                      stroke="{$textColor}" stroke-width="0.5"/>
                <text x="{$startX + 13}" y="{$startY + 30}" font-size="{$fontSize - 2}" font-style="oblique"
                      alignment-baseline="hanging" fill="{$textColor}">players
                </text>
                <text x="{$startX + 24}" y="{$startY + 30}" font-size="{$fontSize - 2}" font-style="oblique"
                      alignment-baseline="hanging" fill="{$textColor}">round
                </text>

                <xsl:for-each select="/Lobby/games/game">
                    <xsl:variable name="currentRectY" select="($startY + 27.5) + (position() * 6)"/>
                    <xsl:variable name="gameID" select="@id"/>
                    <xsl:variable name="players" select="@players"/>
                    <xsl:variable name="round" select="@round"/>
                    <xsl:variable name="maxRounds" select="@maxRounds"/>
                    <rect x="{$startX}" y="{$currentRectY}" width="{$rectWidth - 10}" height="{($rectHeight div 12)-1}"
                          fill="none" style="stroke:{$textColor};stroke-width:{$strokeWidth}"/>
                    <text y="{$currentRectY + 1.5}" fill="{$textColor}" font-size="{$fontSize - 2}"
                          font-family="helvetica">
                        <tspan x="{$startX + 1}" alignment-baseline="hanging">
                            <xsl:value-of select=" concat('Game',$gameID)"/>
                        </tspan>
                        <tspan x="{$startX + 16}" alignment-baseline="hanging">
                            <xsl:value-of select=" concat('|  ',$players)"/>
                        </tspan>
                        <tspan x="{$startX + 22}" alignment-baseline="hanging">
                            <xsl:value-of select=" concat('| ',$round, '/', $maxRounds)"/>
                        </tspan>
                    </text>
                </xsl:for-each>
            </svg>

            <!-- 2. Rechteck - Spielerinfo -->
            <svg x="{$rect2X}" y="{$rectY}" width="{$rectMidWidth}" height="{$rectHeight}"
                 viewBox="0 0 {$rectMidWidth} {$rectHeight}">
                <rect x="0" y="0" width="{$rectMidWidth}" height="{$rectHeight}" fill="none" rx="{$edgeRadius}"
                      ry="{$edgeRadius}"
                      style="stroke:{$textColor};stroke-width:1"/>

                <!-- Spielername -->
                <xsl:variable name="name" select="/Lobby/player/@name"/>
                <xsl:variable name="id" select="/Lobby/player/@id"/>
                <text x="{$rectMidWidth div 2}" y="{$startY + 2.5}" fill="{$textColor}" font-size="{$fontSize+1}"
                      font-family="helvetica" text-anchor="middle"
                      alignment-baseline="hanging">
                    <xsl:value-of select=" concat( $name, ' ', $id)"/>
                </text>

                <!-- Highscore -->
                <xsl:variable name="highscore" select="/Lobby/player/@highscore"/>
                <text x="{$rectMidWidth div 2}" y="{$startY + 15}" fill="{$textColor}" font-size="{$fontSize}"
                      font-family="helvetica"
                      text-anchor="middle"
                      alignment-baseline="hanging">
                    <xsl:value-of select=" concat( 'Highscore: ' ,$highscore)"/>
                </text>

                <!-- Spielstand wiederherstellen-->
                <line x1="{$startX}" y1="{$startY + 25}" x2="{$rectMidWidth - 5}" y2="{$startY + 25}"
                      fill="{$textColor}" stroke="{$textColor}" stroke-width="0.5"/>
                <text fill="{$textColor}" font-size="{$fontSize - 1}" font-family="helvetica"
                      alignment-baseline="hanging">
                    <tspan x="{$startX}" y="{$startY + 34}">Spielstand</tspan>
                    <tspan x="{$startX}" y="{$startY + 39}">wiederherstellen:</tspan>
                </text>
                <rect x="{$startX}" y="{$startY + 42}" width="{$rectMidWidth - 25}" height="{$rectHeight div 12}"
                      fill="none" style="stroke:{$textColor};stroke-width:{$strokeWidth}"/>
                <text x="{$startX + 1}" y="{$startY + 42.5}" fill="{$textColor}" font-size="{$fontSize - 1}"
                      font-family="helvetica"
                      font-style="oblique"
                      alignment-baseline="hanging">
                    Name
                </text>
                <rect x="{$startX + 27}" y="{$startY + 42}" width="{$rectMidWidth - 40}" height="{$rectHeight div 12}"
                      fill="none" style="stroke:{$textColor};stroke-width:{$strokeWidth}"/>
                <text x="{$startX + 28}" y="{$startY + 42.5}" fill="{$textColor}" font-size="{$fontSize - 1}"
                      font-family="helvetica"
                      font-style="oblique"
                      alignment-baseline="hanging">
                    ID
                </text>
                <circle cx="{$rectMidWidth - 4}" cy="{$startY + 44.5}" r="{$fontSize div 2}"
                        stroke-width="{$strokeWidth}" stroke="{$textColor}" fill="none"></circle>
                <text x="{$rectMidWidth - 4}" y="{$startY + 43.5}" fill="lightblue" font-size="{$fontSize - 2}"
                      font-family="helvetica" text-anchor="middle"
                      alignment-baseline="hanging">
                    -->
                </text>
            </svg>

            <!-- 3. Rechteck - HighscoreBoard -->
            <svg x="{$rect3X}" y="{$rectY}" width="{$rectWidth}" height="{$rectHeight}"
                 viewBox="0 0 {$rectWidth} {$rectHeight}">
                <rect x="0" y="0" width="{$rectWidth}" height="{$rectHeight}" fill="none" rx="{$edgeRadius}"
                      ry="{$edgeRadius}"
                      style="stroke:{$textColor};stroke-width:1"/>
                <text x="{$rectWidth div 2}" y="7.5" fill="{$textColor}" font-size="{$fontSize}" font-family="helvetica"
                      text-anchor="middle"
                      alignment-baseline="hanging">
                    Highscores
                </text>

                <!-- Liste der Highscores-->
                <xsl:for-each select="$highscoreBoard/highscores/highscore">
                    <xsl:variable name="currentY" select="($startY + 9) + (position() * 6)"/>
                    <xsl:variable name="position" select="position"/>
                    <xsl:variable name="name" select="name"/>
                    <xsl:variable name="score" select="score"/>

                    <text y="{$currentY}" fill="{$textColor}" font-size="{$fontSize - 2}" font-family="helvetica">
                        <tspan x="{$startX - 3}" alignment-baseline="hanging">
                            <xsl:value-of select="concat($position, $name)"/>
                        </tspan>
                        <tspan x="{$startX + 20}" alignment-baseline="hanging">
                            <xsl:value-of select="$score"/>
                        </tspan>
                    </text>
                </xsl:for-each>
            </svg>
        </svg>
    </xsl:template>

</xsl:stylesheet>