<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:doc="http://nwalsh.com/xsl/documentation/1.0"
	        xmlns:fo="http://www.w3.org/1999/XSL/Format"
        version="1.1"
                exclude-result-prefixes="doc">

<!-- Import chunk.xsl, assumes XSL is a symlink to the docbook xsl-stylesheets 
     see http://sourceforge.net/projects/docbook/ 
     the makefile will try to create the link but may not find it.
-->
  <xsl:import href="XSL/fo/docbook.xsl"/>

  <xsl:variable name="fop.extensions">1</xsl:variable>

  <!-- FOP patheticness prevents figure and table toc entries from working right
	that or maybe its docbook xsl scripts.  anyway, if you add book toc,figure,table,title 
	it all goes pear shaped. -->
  <xsl:param name="generate.toc">
  book      toc,title,index
  /sect1    toc
  </xsl:param>

  <!-- USletter or A4 mostly -->
  <xsl:param name="paper.type" select="'A4'"></xsl:param>

  <xsl:param name="generate.index" select="1"></xsl:param>

  <!-- Footnote ulinks --> 
  <xsl:param name="ulink.show" select="'1'"></xsl:param>
  <xsl:param name="ulink.footnotes" select="'1'"></xsl:param>


  <!-- Number the chapters and sections -->
  <xsl:variable name="section.autolabel">1</xsl:variable>
  <xsl:variable name="section.label.includes.component.label">1</xsl:variable>


  <xsl:template match="authorblurb">
     <fo:block><xsl:call-template name="inline.charseq"/></fo:block>
  </xsl:template>

<!-- custom stuff to add better css hooks -->
<xsl:template match="guibutton">
    <fo:inline font-weight="bold" xsl:use-attribute-sets="monospace.properties"><xsl:call-template name="inline.charseq"/></fo:inline>
</xsl:template>

<xsl:template match="guilabel">
    <fo:inline font-weight="bold" color="rgb(255,0,0)" xsl:use-attribute-sets="monospace.properties"><xsl:call-template name="inline.charseq"/></fo:inline>
</xsl:template>

<xsl:template match="action">
    <fo:inline font-weight="bold" color="rgb(255,0,0)" xsl:use-attribute-sets="monospace.properties"><xsl:call-template name="inline.charseq"/></fo:inline>
</xsl:template>

<xsl:template match="replaceable">
    <fo:inline font-weight="bold" color="rgb(255,0,0)" xsl:use-attribute-sets="monospace.properties"><xsl:call-template name="inline.charseq"/></fo:inline>
</xsl:template>

<xsl:template match="accel">
    <fo:inline text-decoration="underline" font-weight="bold" xsl:use-attribute-sets="monospace.properties"><xsl:call-template name="inline.charseq"/></fo:inline>
</xsl:template>

</xsl:stylesheet>

