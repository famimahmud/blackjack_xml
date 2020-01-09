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
        <xsl:variable name="highscoreBoard" select="document('../HighscoreBoard.xml')"/>

        <xsl:variable name="cardX" select="2.5"/>
        <xsl:variable name="cardY" select="1.5"/>
        <xsl:variable name="cardWidth" select="5"/>
        <xsl:variable name="cardHeight" select="7"/>

        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="100%" height="100%" viewBox="0 0 {$width} {$height}"
             style="background: url(/Users/famimahmud/XML-Praktikum/blackjack/src/static/blackjack/assets/LobbyBackground.svg); background-size: 100% 100%">
            <!-- Überschrift -->
            <!-- Logo -->
            <svg x="{($width div 2)-35}" y="{$height div 15}" width="{$fontSize*3}" height="{$fontSize*3}"
                 viewBox="0 0 10 10">
                <symbol id="leftCard" viewBox="0 0 {$cardWidth} {$cardHeight}">
                    <linearGradient id="gradient1" x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset="0%" style="stop-color:#ffffff;stop-opacity:1"/>
                        <stop offset="100%" style="stop-color:#ffffe6;stop-opacity:1"/>
                    </linearGradient>
                    <rect x="0"
                          y="0"
                          width="5"
                          height="7"
                          rx="0.25"
                          ry="0.25"
                          fill="url(#gradient1)"
                          style="stroke:black;stroke-width:0.03"/>
                    <symbol id="valueBox1">
                        <svg height="2" width="1" viewBox="0 0 1 2">
                            <text x="0.05"
                                  y="0.8"
                                  font-size="0.8"
                                  font-family="serif"
                                  fill="black">A
                            </text>
                            <image x="0"
                                   y="1"
                                   width="0.6"
                                   height="0.6"
                                   xlink:href="/Users/famimahmud/XML-Praktikum/blackjack/src/static/blackjack/assets/icons/Club.svg"/>
                        </svg>
                    </symbol>
                    <use xlink:href="#valueBox1" x="0.2" y="0"/>
                    <use xlink:href="#valueBox1"
                         x="0.2"
                         y="0"
                         transform="rotate(180 2.5 3.5)"/>
                    <svg x="0.5"
                         y="1"
                         width="4"
                         height="5"
                         viewBox="0 0 5 7"
                         preserveAspectRatio="none">
                        <image x="2"
                               y="3"
                               width="1"
                               height="1"
                               xlink:href="/Users/famimahmud/XML-Praktikum/blackjack/src/static/blackjack/assets/icons/Club.svg"/>
                    </svg>
                </symbol>

                <symbol id="rightCard" viewBox="0 0 {$cardWidth} {$cardHeight}">
                    <linearGradient id="gradient2" x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset="0%" style="stop-color:#ffffff;stop-opacity:1"/>
                        <stop offset="100%" style="stop-color:#ffffe6;stop-opacity:1"/>
                    </linearGradient>
                    <rect x="0"
                          y="0"
                          width="5"
                          height="7"
                          rx="0.25"
                          ry="0.25"
                          fill="url(#gradient2)"
                          style="stroke:black;stroke-width:0.03"/>
                    <symbol id="valueBox2">
                        <svg height="2" width="1" viewBox="0 0 1 2">
                            <text x="0.05"
                                  y="0.8"
                                  font-size="0.8"
                                  font-family="serif"
                                  fill="red">K
                            </text>
                            <image x="0"
                                   y="1"
                                   width="0.6"
                                   height="0.6"
                                   xlink:href="/Users/famimahmud/XML-Praktikum/blackjack/src/static/blackjack/assets/icons/Heart.svg"/>
                        </svg>
                    </symbol>
                    <use xlink:href="#valueBox2" x="0.2" y="0"/>
                    <use xlink:href="#valueBox2"
                         x="0.2"
                         y="0"
                         transform="rotate(180 2.5 3.5)"/>
                    <image x="0.1"
                           y="1"
                           width="4.9"
                           height="5"
                           xlink:href="/Users/famimahmud/XML-Praktikum/blackjack/src/static/blackjack/assets/icons/red/King.svg"/>
                </symbol>
                <use xlink:href="#leftCard" x="{$cardX}" y="{$cardY}" width="{$cardWidth}" height="{$cardHeight}"
                     transform="rotate(340,5,5)"/>
                <use xlink:href="#rightCard" x="{$cardX}" y="{$cardY}" width="{$cardWidth}" height="{$cardHeight}"
                     transform="rotate(20,5,5)"/>
            </svg>

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

                <xsl:for-each select="Lobby/games/game">
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
                <xsl:variable name="name" select="Lobby/player/@name"/>
                <xsl:variable name="id" select="Lobby/player/@id"/>
                <text x="{$rectMidWidth div 2}" y="{$startY + 2.5}" fill="{$textColor}" font-size="{$fontSize+1}"
                      font-family="helvetica" text-anchor="middle"
                      alignment-baseline="hanging">
                    <xsl:value-of select=" concat( $name, ' ', $id)"/>
                </text>

                <!-- Highscore -->
                <xsl:variable name="highscore" select="Lobby/player/@highscore"/>
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