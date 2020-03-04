<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes"/>

    <xsl:template match="/">
        <xsl:param name="isLoggedIn"/>
        <xsl:param name="playerName"/>
        <xsl:param name="playerId"/>
        <xsl:param name="playerHighscore"/>

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

        <xsl:variable name="cardX" select="2.5"/>
        <xsl:variable name="cardY" select="1.5"/>
        <xsl:variable name="cardWidth" select="5"/>
        <xsl:variable name="cardHeight" select="7"/>

        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="100%" height="100%" viewBox="0 0 {$width} {$height}">

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
                <rect class="separatorRect" x="0" y="0" width="{$rectWidth}" height="{$rectHeight}" fill="none"
                      rx="{$edgeRadius}"
                      ry="{$edgeRadius}"/>
                <!-- Button für neues Spiel-->
                <xsl:choose>
                    <xsl:when test="$isLoggedIn = 1">
                        <xsl:variable name="name" select="$playerName"/>
                        <xsl:variable name="id" select="$playerId"/>
                        <text text-decoration="underline" x="{$startX}" y="{$startY}" font-size="{$fontSize - 1}"
                              alignment-baseline="hanging"
                              fill="{$textColor}" font-family="{$fonts}">New Game:
                        </text>
                        <foreignObject width="100%" height="100%" x="{$startX}" y="{$startY - 1}">
                            <form xmlns="http://www.w3.org/1999/xhtml" action="/blackjack/newGame" method="get"
                                  id="newGame">
                                <input type="hidden" name="playerName" id="newPlayerName" value="{$name}"/>
                                <input type="hidden" name="playerId" id="newPlayerId" value="{$id}"/>
                                <button id="singlePlayerButton" name="singlePlayer" value="true">
                                    Singleplayer
                                </button>
                                <button id="multiPlayerButton" name="singlePlayer" value="false">
                                    Multiplayer
                                </button>
                            </form>
                        </foreignObject>
                    </xsl:when>
                    <xsl:otherwise>
                        <text font-size="{$fontSize - 1}" alignment-baseline="hanging"
                              fill="{$textColor}" font-family="{$fonts}">
                            <tspan x="{$startX}" y="{$startY + 10}">Create or restore</tspan>
                            <tspan x="{$startX}" y="{$startY+ 14}">your account!</tspan>
                        </text>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- Liste der Spiele -->
                <text x="{$startX}" y="{$startY + 26}" font-size="{$fontSize - 1}" alignment-baseline="hanging"
                      text-decoration="underline" fill="{$textColor}" font-family="{$fonts}">Games:
                </text>

                <xsl:choose>
                    <xsl:when test="count(games/game[@singlePlayer = 'false' and @phase = 'bet']) = 0">
                        <text x="{$startX + 4}" y="45" font-size="{$fontSize - 2}"
                              font-style="oblique"
                              alignment-baseline="hanging" fill="{$textColor}" font-family="{$fonts}">No active games
                        </text>
                    </xsl:when>
                    <xsl:otherwise>
                        <text x="{$startX + 22}" y="{$startY + 30}" font-size="{$fontSize - 2}" font-style="oblique"
                              alignment-baseline="hanging" fill="{$textColor}" font-family="{$fonts}">players
                        </text>
                        <foreignObject id="gameContainer" x="{$startX}" y="39" width="80%" height="20"
                                       font-family="{$fonts}" font-size="{$fontSize - 1}">
                            <xsl:for-each select="games/game[@singlePlayer = 'false' and @phase = 'bet']">
                                <xsl:variable name="currentRectY" select="0 + ((position() - 1) * 6)"/>
                                <xsl:variable name="gameID" select="@id"/>
                                <xsl:variable name="players" select="count(players/player)"/>

                                <form xmlns="http://www.w3.org/1999/xhtml" action="/blackjack/{$gameID}/joinGame"
                                      method="post"
                                      id="joinButton{$gameID}">
                                    <label>
                                        <input class="joinGameButton" type="submit" name="gameId" id="{$gameID}Button"
                                               value="{concat('Game#', $gameID, '  -  ', $players)}"/>
                                        <input type="hidden" name="playerId" id="{$gameID}playerId"
                                               value="{$playerId}"/>
                                    </label>
                                </form>
                            </xsl:for-each>
                        </foreignObject>
                    </xsl:otherwise>
                </xsl:choose>
            </svg>

            <!-- 2. Rechteck - Spielerinfo -->
            <svg x="{$rect2X}" y="{$rectY}" width="{$rectMidWidth}" height="{$rectHeight}"
                 viewBox="0 0 {$rectMidWidth} {$rectHeight}">
                <rect class="separatorRect" x="0" y="0" width="{$rectMidWidth}" height="{$rectHeight}" fill="none"
                      rx="{$edgeRadius}"
                      ry="{$edgeRadius}"/>

                <!-- Spielername -->
                <xsl:choose>
                    <xsl:when test="$isLoggedIn = 1">
                        <xsl:variable name="name" select="$playerName"/>
                        <xsl:variable name="id" select="$playerId"/>
                        <text x="{$rectMidWidth div 2}" y="{$startY + 1.5}" fill="{$textColor}"
                              font-size="{$fontSize+1}"
                              font-family="{$fonts}" text-anchor="middle"
                              alignment-baseline="hanging">
                            <xsl:value-of select="$name"/>
                        </text>
                        <text x="{$rectMidWidth div 2}" y="{$startY + 8}" fill="{$textColor}"
                              font-size="{$fontSize - 2}"
                              font-family="{$fonts}" text-anchor="middle"
                              alignment-baseline="hanging">
                            <xsl:value-of select="concat('ID: ', $id)"/>
                        </text>

                        <!-- Highscore -->
                        <text x="{$rectMidWidth div 2}" y="{$startY + 15}" fill="{$textColor}" font-size="{$fontSize}"
                              font-family="{$fonts}"
                              text-anchor="middle"
                              alignment-baseline="hanging">
                            <xsl:value-of select=" concat( 'Highscore: ' , $playerHighscore, '$')"/>
                        </text>
                    </xsl:when>
                    <xsl:otherwise>
                        <foreignObject width="100%" height="100%" font-family="{$fonts}" fill="{$textColor}"
                                       font-size="{$fontSize - 1}" x="{$startX}" y="{$startY}">
                            <form xmlns="http://www.w3.org/1999/xhtml" action="/blackjack/createAccount" method="post"
                                  id="createAccount">
                                <input class="inputBox" size="36" type="text" name="playerName" id="playerName1"
                                       placeholder="Name"/>
                                <br/>
                                <button class="accountButton" form="createAccount" value="Submit">
                                    Create account
                                </button>
                            </form>
                        </foreignObject>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- Account wiederherstellen-->
                <line x1="{$startX}" y1="{$startY + 25}" x2="{$rectMidWidth - 5}" y2="{$startY + 25}"
                      fill="{$rectColor}" stroke="{$textColor}" stroke-width="0.5"/>

                <foreignObject width="100%" height="100%" font-family="{$fonts}" fill="{$textColor}"
                               font-size="{$fontSize - 1}" x="{$startX}" y="{$startY+30}">
                    <form xmlns="http://www.w3.org/1999/xhtml" action="/blackjack/lobby" method="get"
                          id="restoreAccount">
                        <input size="23" class="inputBox" type="text" name="playerName" id="playerName"
                               placeholder="Name"/>
                        <input size="8" class="inputBox" type="text" name="playerId" id="playerId" placeholder="ID"/>
                        <br/>
                        <button class="accountButton" form="restoreAccount" value="Submit">
                            Restore account
                        </button>
                    </form>
                </foreignObject>
            </svg>

            <!-- 3. Rechteck - HighscoreBoard -->
            <svg x="{$rect3X}" y="{$rectY}" width="{$rectWidth}" height="{$rectHeight}"
                 viewBox="0 0 {$rectWidth} {$rectHeight}">
                <rect x="0" y="0" class="separatorRect" width="{$rectWidth}" height="{$rectHeight}" fill="none"
                      rx="{$edgeRadius}"
                      ry="{$edgeRadius}"/>
                <text x="{$rectWidth div 2}" y="7.5" fill="{$textColor}" font-size="{$fontSize}" font-family="{$fonts}"
                      text-anchor="middle" text-decoration="underline" alignment-baseline="hanging">
                    Highscores
                </text>


                <!-- Liste der Highscores-->
                <xsl:choose>
                    <xsl:when test="count(games/scores/score) = 0">
                        <text y="{$rectHeight div 2}" fill="{$textColor}" font-size="{$fontSize - 2}"
                              font-family="{$fonts}" font-style="oblique">
                            <tspan x="10" alignment-baseline="hanging">
                                No Highscores
                            </tspan>
                        </text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="games/scores/score">
                            <!-- Sort by scores -->
                            <xsl:sort select="node()" data-type="number" order="descending"/>
                            <xsl:variable name="currentY" select="($startY + 6) + (position() * 4)"/>
                            <xsl:variable name="position" select="position()"/>
                            <xsl:variable name="name" select="@name"/>
                            <xsl:variable name="score" select="node()"/>

                            <xsl:if test="not($position > 10)">
                                <text y="{$currentY}" fill="{$textColor}" font-size="{$fontSize - 2}"
                                      font-family="{$fonts}">
                                    <tspan x="{$startX - 3}" alignment-baseline="hanging">
                                        <xsl:value-of select="concat($position, '. ', $name)"/>
                                    </tspan>
                                    <tspan x="{$startX + 20}" alignment-baseline="hanging">
                                        <xsl:value-of select="concat($score, '$')"/>
                                    </tspan>
                                </text>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </svg>
        </svg>
    </xsl:template>

</xsl:stylesheet>
