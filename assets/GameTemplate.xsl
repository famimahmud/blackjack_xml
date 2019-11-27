<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes"/>

    <xsl:template match="/">

        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="100%" height="100%" viewBox="0 0 1500 1000" stroke="white"
             font-family="Helvetica, Arial, sans-serif" font-size="40" style="background: url(TableBackground.svg); background-size: 100% 100%">

            <!--<rect fill="url(#gradient)" width="100%" height="100%"/>-->

            <path id="infoBow" d="M300 400 Q750 500, 1200 400" stroke-width="3px" fill="none"/>
            <path d="M300 500 Q750 600, 1200 500" stroke-width="3px" fill="none"/>
            <path d="M300 400 L300 500" stroke-width="3px"/>
            <path d="M1200 400 L1200 500" stroke-width="3px"/>

            <text dy="-40" fill="white" stroke="none" text-anchor="middle" alignment-baseline="central">
                <textPath xlink:href="#infoBow" fill="white" startOffset="450"> It's Alice's turn! </textPath>
            </text>

            <rect x="1100" y="70" width="110" height="150" rx="20" ry="20" fill="none" stroke-width="3px"/>

            <text x="750" y="60" text-anchor="middle" alignment-baseline="central" fill="white" stroke="none">
                Dealer
            </text>
            <rect x="650" y="100" width="200" height="150" rx="20" ry="20" fill="none" stroke-width="3px"/>

            <text x="750" y="840" text-anchor="middle" alignment-baseline="central" fill="white" stroke="none">
                Bob
            </text>
            <rect x="650" y="650" width="200" height="150" rx="20" ry="20" fill="none" stroke-width="3px"/>

            <svg stroke="gold">
                <text x="280" y="840" text-anchor="middle" alignment-baseline="central" fill="gold" stroke="none"
                      transform="rotate(9, 500 820)">Alice
                </text>
                <rect x="200" y="650" width="200" height="150" rx="20" ry="20" fill="none" stroke-width="3px"
                      transform="rotate(10, 500, 750)"/>
            </svg>
            <text x="1220" y="840" text-anchor="middle" alignment-baseline="central" fill="white" stroke="none"
                  transform="rotate(-9, 1000 820)">You
            </text>
            <rect x="1100" y="650" width="200" height="150" rx="20" ry="20" fill="none" stroke-width="3px"
                  transform="rotate(-10, 1000, 750)"/>
        </svg>

    </xsl:template>

</xsl:stylesheet>
