<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes"/>

    <xsl:template match="/">
        <xsl:variable name="width" select="150"/>
        <xsl:variable name="height" select="100"/>
        <xsl:variable name="fontSize" select="5"/>
        <xsl:variable name="textColor" select="'white'"/>
        <xsl:variable name="rectColor" select="'black'"/>
        <xsl:variable name="fonts" select="'Raleway, sans-serif'"/>
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
        <xsl:variable name="highscoreBoard" select="document('../Highscores.xml')"/>

        <xsl:variable name="cardX" select="2.5"/>
        <xsl:variable name="cardY" select="1.5"/>
        <xsl:variable name="cardWidth" select="5"/>
        <xsl:variable name="cardHeight" select="7"/>

        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="100%" height="100%" viewBox="0 0 {$width} {$height}"
             >

            <!-- Import online fonts -->
            <defs>
                <style type="text/css">@import url('https://fonts.googleapis.com/css?family=Raleway');</style>
            </defs>

            <!-- Überschrift -->
            <!-- Logo -->
            <image x="{($width div 2)-35}" y="{$height div 15}"
                   width="{$fontSize*3}" height="{$fontSize*3}"
                   xlink:href="/static/blackjack/assets/icons/Logo.svg"/>

            <text x="{$width div 2 + 5}" y="{$height div 10}" fill="{$textColor}" font-size="{$fontSize * 2}"
                  font-family="{$fonts}" text-anchor="middle"
                  alignment-baseline="hanging">
                Blackjack
            </text>

            <!-- 1. Rechteck - Spiele -->
            <svg x="{$startX}" y="{$rectY}" width="{$rectWidth}" height="{$rectHeight}"
                 viewBox="0 0 {$rectWidth} {$rectHeight}">
                <rect x="0" y="0" width="{$rectWidth}" height="{$rectHeight}" fill="none" rx="{$edgeRadius}"
                      ry="{$edgeRadius}"
                      style="fill: #134900; opacity: 0.6"/>
                <!-- Button für neues Spiel-->
                <xsl:variable name="name" select="lobby/player/@name"/>
                <xsl:variable name="id" select="lobby/player/@id"/>
                <foreignObject width="100%" height="100%" x="{$startX}" y="{$startY - 1}">
                    <form xmlns="http://www.w3.org/1999/xhtml" action="/blackjack/newRound" method="get" id="Neues Spiel">
                        <input type="hidden" name="name" id="name" value="{$name}"/>
                        <input type="hidden" name="id" id="id" value="{$id}"/>
                        <button style=" width:80%; height:20%; display:table-cell; font-size:{$fontSize - 1}; color: white; border-radius:1px; border: none; vertical-align: middle; background-color: #ED4416 ; cursor: pointer; position: absolute;"
                                form="Neues Spiel" value="Submit">
                            Neues Spiel
                        </button>
                    </form>
                </foreignObject>
                <!-- Einzelspiel Abfrage -->
                <rect x="{$startX}" y="{$startY + 13}" width="{$rectWidth - 35}" height="{$rectHeight div 12}"
                      fill="none" style="stroke:{$rectColor} ;stroke-width:{$strokeWidth }"/>
                <text x="{$startX + 1}" y="{$startY + 14}" font-size="{$fontSize}" alignment-baseline="hanging"
                      fill="{$textColor}">√
                </text>
                <text x="{$startX + 8}" y="{$startY + 14}" font-size="{$fontSize - 1}" alignment-baseline="hanging"
                      fill="{$textColor}" font-family="{$fonts}">Single-Player?
                </text>

                <!-- Liste der Spiele -->
                <text x="{$startX}" y="{$startY + 22}" font-size="{$fontSize}" alignment-baseline="hanging"
                      fill="{$textColor}" font-family="{$fonts}">Spiele:
                </text>
                <line x1="{$startX}" y1="{$startY + 27}" x2="{$startX + 14}" y2="{$startY + 27}" fill="{$textColor}"
                      stroke="{$textColor}" stroke-width="0.5"/>
                <text x="{$startX + 13}" y="{$startY + 30}" font-size="{$fontSize - 2}" font-style="oblique"
                      alignment-baseline="hanging" fill="{$textColor}" font-family="{$fonts}">players
                </text>
                <text x="{$startX + 24}" y="{$startY + 30}" font-size="{$fontSize - 2}" font-style="oblique"
                      alignment-baseline="hanging" fill="{$textColor}" font-family="{$fonts}">round
                </text>

                <xsl:for-each select="lobby/games/game">
                    <xsl:variable name="currentRectY" select="($startY + 27.5) + (position() * 6)"/>
                    <xsl:variable name="gameID" select="@id"/>
                    <xsl:variable name="players" select="@players"/>
                    <xsl:variable name="round" select="@round"/>
                    <xsl:variable name="maxRounds" select="@maxRounds"/>
                    <rect x="{$startX}" y="{$currentRectY}" width="{$rectWidth - 10}" height="{($rectHeight div 12)-1}"
                          fill="none" style="stroke:{$rectColor};stroke-width:{$strokeWidth - 0.2}"/>
                    <text y="{$currentRectY + 1}" fill="{$textColor}" font-size="{$fontSize - 2}"
                          font-family="{$fonts}">
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
                      style="fill: #134900; opacity: 0.6"/>

                <!-- Spielername -->
                <xsl:variable name="name" select="lobby/player/@name"/>
                <xsl:variable name="id" select="lobby/player/@id"/>
                <text x="{$rectMidWidth div 2}" y="{$startY + 2.5}" fill="{$textColor}" font-size="{$fontSize+1}"
                      font-family="{$fonts}" text-anchor="middle"
                      alignment-baseline="hanging">
                    <xsl:value-of select=" concat( $name, ' ', $id)"/>
                </text>

                <!-- Highscore -->
                <xsl:variable name="highscore" select="lobby/player/@highscore"/>
                <text x="{$rectMidWidth div 2}" y="{$startY + 15}" fill="{$textColor}" font-size="{$fontSize}"
                      font-family="{$fonts}"
                      text-anchor="middle"
                      alignment-baseline="hanging">
                    <xsl:value-of select=" concat( 'Highscore: ' ,$highscore)"/>
                </text>

                <!-- Spielstand wiederherstellen-->
                <line x1="{$startX}" y1="{$startY + 25}" x2="{$rectMidWidth - 5}" y2="{$startY + 25}"
                      fill="{$rectColor}" stroke="{$textColor}" stroke-width="0.5"/>

                <!--<text fill="{$textColor}" font-size="{$fontSize - 1}" font-family="helvetica"
=======
                <text fill="{$textColor}" font-size="{$fontSize - 1}" font-family="{$fonts}"
>>>>>>> 61dac9c44d39b320aaad735030eae76bacba3251
                      alignment-baseline="hanging">
                    <tspan x="{$startX}" y="{$startY + 34}">Spielstand</tspan>
                    <tspan x="{$startX}" y="{$startY + 39}">wiederherstellen:</tspan>
                </text>-->

                <!--  TODO: Change label font-family -->
                <foreignObject width="100%" height="100%" font-family="helvetica" fill="{$textColor}" font-size="{$fontSize - 1}" x="{$startX}" y="{$startY+30}">
                    <form xmlns="http://www.w3.org/1999/xhtml" action="/blackjack/restore" method="post" id="restore" >
                        <input  size="23" type="text" name="playerName" id="playerName" style="outline:none; font-size:{$fontSize - 2}; border: none" placeholder="Name"/>
                        <input  size="8" type="text" name="playerID" id="playerID" style="outline:none; font-size:{$fontSize - 2}; border: none" placeholder="ID"/> <br/>
                        <button style=" width:40px; height:10px; display:table-cell; font-size:{$fontSize - 2}; color: white; border-radius:1px; border: none; vertical-align: middle; background-color: #ED4416 ; cursor: pointer; position: absolute;"
                                form="restore" value="Submit">
                            Spielstand wiederherstellen
                        </button>
                    </form>
                </foreignObject>



                <!--
                <rect x="{$startX}" y="{$startY + 42}" width="{$rectMidWidth - 25}" height="{$rectHeight div 12}"
                      fill="none" style="stroke:{$rectColor};stroke-width:{$strokeWidth - 0.2}"/>
                <text x="{$startX + 1}" y="{$startY + 42.5}" fill="{$textColor}" font-size="{$fontSize - 1}"
                      font-family="{$fonts}"
                      font-style="oblique"
                      alignment-baseline="hanging">
                    Name
                </text>
                <rect x="{$startX + 27}" y="{$startY + 42}" width="{$rectMidWidth - 40}" height="{$rectHeight div 12}"
                      fill="none" style="stroke:{$rectColor};stroke-width:{$strokeWidth - 0.2}"/>
                <text x="{$startX + 28}" y="{$startY + 42.5}" fill="{$textColor}" font-size="{$fontSize - 1}"
                      font-family="{$fonts}"
                      font-style="oblique"
                      alignment-baseline="hanging">
                    ID
                </text>
                <circle cx="{$rectMidWidth - 4}" cy="{$startY + 44.5}" r="{$fontSize div 2}"
                        stroke-width="{$strokeWidth}" stroke="{$rectColor}" fill="none"></circle>
                <text x="{$rectMidWidth - 4}" y="{$startY + 43.4}" fill="lightblue" font-size="{$fontSize - 2}"
                      font-family="{$fonts}" text-anchor="middle"
                      alignment-baseline="hanging">
                    -->
                <!--</text> -->
            </svg>

            <!-- 3. Rechteck - HighscoreBoard -->
            <svg x="{$rect3X}" y="{$rectY}" width="{$rectWidth}" height="{$rectHeight}"
                 viewBox="0 0 {$rectWidth} {$rectHeight}">
                <rect x="0" y="0" width="{$rectWidth}" height="{$rectHeight}" fill="none" rx="{$edgeRadius}"
                      ry="{$edgeRadius}"
                      style="fill: #134900; opacity: 0.6"/>
                <text x="{$rectWidth div 2}" y="7.5" fill="{$textColor}" font-size="{$fontSize}" font-family="{$fonts}"
                      text-anchor="middle"
                      alignment-baseline="hanging">
                    Highscores
                </text>

                <!-- Liste der Highscores-->
                <xsl:for-each select="$highscoreBoard/highscores/highscore">
                    <xsl:variable name="currentY" select="($startY + 6) + (position() * 4)"/>
                    <xsl:variable name="position" select="@position"/>
                    <xsl:variable name="name" select="name"/>
                    <xsl:variable name="score" select="score"/>

                    <text y="{$currentY}" fill="{$textColor}" font-size="{$fontSize - 2}" font-family="{$fonts}">
                        <tspan x="{$startX - 3}" alignment-baseline="hanging">
                            <xsl:value-of select="concat($position, '. ', $name)"/>
                        </tspan>
                        <tspan x="{$startX + 20}" alignment-baseline="hanging">
                            <xsl:value-of select="concat($score, '$')"/>
                        </tspan>
                    </text>
                </xsl:for-each>
            </svg>
        </svg>
    </xsl:template>

</xsl:stylesheet>
