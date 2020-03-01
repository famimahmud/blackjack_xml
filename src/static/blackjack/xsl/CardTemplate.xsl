<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes"/>

    <xsl:template name="CardTemplate">
        <xsl:param name="cardValue"/>
        <xsl:param name="cardType"/>
        <xsl:param name="id"/>

        <xsl:variable name="cardWidth" select="5"/>
        <xsl:variable name="cardHeight" select="7"/>
        <xsl:variable name="edgeRadius" select="0.25"/>
        <xsl:variable name="strokeWidth" select="0.03"/>
        <xsl:variable name="fonts" select="'Raleway, sans-serif'"/>
        <xsl:variable name="values" select="document('../assets/Values.xml')"/>

        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             font-family="{$fonts}" width="75%" height="100%" viewBox="0 0 {$cardWidth} {$cardHeight}">

            <linearGradient id="gradient" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" style="stop-color:#ffffff;stop-opacity:1"/>
                <stop offset="100%" style="stop-color:#ffffe6;stop-opacity:1"/>
            </linearGradient>

            <rect x="0" y="0"
                  width="{$cardWidth}" height="{$cardHeight}"
                  rx="{$edgeRadius}" ry="{$edgeRadius}" fill="url(#gradient)"
                  style="stroke:black;stroke-width:{$strokeWidth}"/>

            <xsl:choose>
                <xsl:when test="@hidden = 'true'">
                    <!-- Card is hidden: only show reverse -->

                    <xsl:variable name="patternSize" select="0.5"/>
                    <xsl:variable name="lineWidth" select="0.05"/>

                    <pattern id="pattern"
                             patternUnits="userSpaceOnUse"
                             width="{$patternSize}"
                             height="{$patternSize}"
                             fill="red"
                             viewBox="0 0 {$patternSize} {$patternSize}" preserveAspectRatio="none">

                        <rect x="0" y="0" width="{$patternSize}" height="{$patternSize}" style="fill:red"/>
                        <line x1="-0.1" y1="-0.1" x2="{$patternSize + 0.1}" y2="{$patternSize + 0.1}" style="stroke:white;stroke-width:{$lineWidth}" />
                        <line x1="-0.1" y1="{$patternSize + 0.1}" x2="{$patternSize + 0.1}" y2="-0.1" style="stroke:white;stroke-width:{$lineWidth}" />
                    </pattern>

                    <rect x="0.5" y="0.5"
                          rx="0.25" ry="0.25"
                          height="6" width="4"
                          style="fill:url(#pattern);stroke:red;stroke-width:0.1"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Generate card front -->

                    <!-- Choose card color from type -->
                    <xsl:variable name="cardColor">
                        <xsl:choose>
                            <xsl:when test="$cardType = 'Heart' or $cardType = 'Diamond'">red</xsl:when>
                            <xsl:otherwise>black</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!-- Choose x position of text depending on value -->
                    <xsl:variable name="textX">
                        <xsl:choose>
                            <xsl:when
                                    test="$cardValue = 'A' or $cardValue = 'K'">0.05</xsl:when>
                            <xsl:when test="$cardValue = 'Q'">0</xsl:when>
                            <xsl:when test="$cardValue = 'J'">0.15</xsl:when>
                            <xsl:when test="$cardValue = '10'">-0.1</xsl:when>
                            <xsl:otherwise>0.1</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>

                    <symbol id="valueBox{$id}">
                        <svg height="2" width="1" viewBox="0 0 1 2">
                            <text x="{$textX}" y="0.8" font-size="0.8" font-family="{$fonts}" fill="{$cardColor}">
                                <xsl:value-of select="$cardValue"/>
                            </text>
                            <image x="0" y="1" width="0.6" height="0.6" xlink:href="/static/blackjack/assets/icons/{$cardType}.svg"/>
                        </svg>
                    </symbol>

                    <!-- Upper left corner -->
                    <use xlink:href="#valueBox{$id}" x="0.2" y="0"/>
                    <!-- Bottom right corner -->
                    <use xlink:href="#valueBox{$id}" x="0.2" y="0" transform="rotate(180 2.5 3.5)"/>

                    <xsl:choose>
                        <!-- Use King, Queen or Jack asset -->
                        <xsl:when test="$cardValue = 'K'">
                            <image x="0.1" y="1" width="4.9" height="5" xlink:href="/static/blackjack/assets/icons/{$cardColor}/King.svg"/>
                        </xsl:when>
                        <xsl:when test="$cardValue = 'Q'">
                            <image x="0.1" y="1" width="4.9" height="5" xlink:href="/static/blackjack/assets/icons/{$cardColor}/Queen.svg"/>
                        </xsl:when>
                        <xsl:when test="$cardValue = 'J'">
                            <image x="0.1" y="1" width="4.9" height="5" xlink:href="/static/blackjack/assets/icons/{$cardColor}/Jack.svg"/>
                        </xsl:when>

                        <!-- Otherwise generate asset from number count -->
                        <xsl:otherwise>
                            <svg x="0.5" y="1" width="4" height="5" viewBox="0 0 5 7" preserveAspectRatio="none">
                                <xsl:for-each select="$values/*/value[@character=$cardValue]/child::point">
                                    <xsl:variable name="currentX" select="x"/>
                                    <xsl:variable name="currentY" select="y"/>
                                    <xsl:choose>
                                        <xsl:when test="@rotate = 'true'">
                                            <image x="{$currentX}" y="{$currentY}" width="1" height="1"
                                                   xlink:href="/static/blackjack/assets/icons/{$cardType}.svg" transform="rotate(180 {$currentX + 0.5} {$currentY + 0.5})"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <image x="{$currentX}" y="{$currentY}" width="1" height="1" xlink:href="/static/blackjack/assets/icons/{$cardType}.svg"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                            </svg>
                        </xsl:otherwise>
                    </xsl:choose>

                </xsl:otherwise>
            </xsl:choose>
        </svg>
    </xsl:template>

</xsl:stylesheet>
