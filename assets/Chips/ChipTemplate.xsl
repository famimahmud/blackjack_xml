<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes"/>

    <xsl:template name="ChipTemplate">
        <xsl:param name="chipValue"/>
        <xsl:param name="id"/>
        <!-- <xsl:variable name="chipValue" select="/*/value"/> -->
        
        <xsl:variable name="root2" select="1.4142"/>
        <xsl:variable name="root2Inv" select="0.7071"/>
        <xsl:variable name="r" select="1"/>
        <xsl:variable name="r2" select="0.75"/>
        <xsl:variable name="r3" select="0.65"/>
        <xsl:variable name="d" select="2"/>
        
        <xsl:variable name="p0X" select="0"/>
        <xsl:variable name="p0Y" select="-$r"/>
        <xsl:variable name="p1X" select="$root2Inv"/>
        <xsl:variable name="p1Y" select="-$root2Inv"/>
        <xsl:variable name="p2X" select="$r"/>
        <xsl:variable name="p2Y" select="0"/>
        <xsl:variable name="p3X" select="$root2Inv"/>
        <xsl:variable name="p3Y" select="$root2Inv"/>
        <xsl:variable name="p4X" select="0"/>
        <xsl:variable name="p4Y" select="$r"/>
        <xsl:variable name="p5X" select="-$root2Inv"/>
        <xsl:variable name="p5Y" select="$root2Inv"/>
        <xsl:variable name="p6X" select="-$r"/>
        <xsl:variable name="p6Y" select="0"/>
        <xsl:variable name="p7X" select="-$root2Inv"/>
        <xsl:variable name="p7Y" select="-$root2Inv"/>

        <xsl:variable name="cX" select="0"/>
        <xsl:variable name="cY" select="0"/>

        <xsl:variable name="rPlus" select="1.1"/>
        <xsl:variable name="dPlus" select="2.2"/>

        <xsl:variable name="chipColor">
            <xsl:choose>
                <xsl:when test="$chipValue = 10">white</xsl:when>
                <xsl:when test="$chipValue = 50">red</xsl:when>
                <xsl:when test="$chipValue = 100">darkgreen</xsl:when>
                <xsl:when test="$chipValue = 250">darkorange</xsl:when>
                <xsl:when test="$chipValue = 500">darkorchid</xsl:when>
                <xsl:when test="$chipValue = 1000">black</xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="strokeColor">
            <xsl:choose>
                <xsl:when test="$chipValue = 10">blue</xsl:when>
                <xsl:otherwise>white</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="fonts" select="'Raleway, serif'"/>
        <xsl:variable name="fontSize">
            <xsl:choose>
                <xsl:when test="$chipValue = 1000">0.5</xsl:when>
                <xsl:otherwise>0.75</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="textY">
            <xsl:choose>
                <xsl:when test="$chipValue = 1000">0.15</xsl:when>
                <xsl:otherwise>-0.25</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>


        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="100%" height="100%" font-family="{$fonts}">

            <symbol id = "outerChip{$id}" viewBox="-{$rPlus} -{$rPlus} {$dPlus} {$dPlus}">
                <circle cx="0" cy="0" r="{$r}" fill= "{$chipColor}"/>
                <line x1="{$p0X}" y1="{$p0Y}" x2="{$p4X}" y2="{$p4Y}" style="fill:none; stroke:{$strokeColor}; stroke-width:0.2"/>
                <line x1="{$p2X}" y1="{$p2Y}" x2="{$p6X}" y2="{$p6Y}" style="fill:none; stroke:{$strokeColor}; stroke-width:0.2"/>
                <line x1="{$p1X}" y1="{$p1Y}" x2="{$p5X}" y2="{$p5Y}" style="fill:none; stroke:{$strokeColor}; stroke-width:0.2"/>
                <line x1="{$p3X}" y1="{$p3Y}" x2="{$p7X}" y2="{$p7Y}" style="fill:none; stroke:{$strokeColor}; stroke-width:0.2"/>
            </symbol>

            <symbol id="innerChip{$id}" viewBox="-{$rPlus} -{$rPlus} {$dPlus} {$dPlus}">
                <use x="-{$rPlus}" y="-{$rPlus}" width="100%" height="100%" xlink:href="#outerChip{$id}"/>
                <circle cx="0" cy="0" r="{$r2}" fill= "{$chipColor}"/>
            </symbol>

            <symbol id="chip{$id}" viewBox="-{$rPlus} -{$rPlus} {$dPlus} {$dPlus}" preserveAspectRatio="xMidYMid meet" >
                <use x="-{$rPlus}" y="-{$rPlus}" width="100%" height="100%" xlink:href="#innerChip{$id}"/>
                <circle cx="0" cy="0" r="{$r3}" fill= "none" stroke="{$strokeColor}" stroke-width="0.05" stroke-dasharray="0.2,0.2"/>
                <text x="{$cX}" y="{$textY}" fill="{$strokeColor}" font-size="{$fontSize}" text-anchor="middle" alignment-baseline="central">
                    <xsl:value-of select="$chipValue"/>
                </text>
            </symbol>

            <svg viewBox="0 0 100 100" preserveAspectRatio="xMidYMid meet">
                <use x="0" y="0" width="100" height="100" xlink:href="#chip{$id}"/>
            </svg>

        </svg>
    </xsl:template>

</xsl:stylesheet>
