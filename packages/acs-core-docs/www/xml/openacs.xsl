<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:doc="http://nwalsh.com/xsl/documentation/1.0"
        version="1.1"
                exclude-result-prefixes="doc">

<!-- Import chunk.xsl, assumes XSL is a symlink to the docbook xsl-stylesheets 
     see http://sourceforge.net/projects/docbook/ 
     the makefile will try to create the link but may not find it.
-->
  <xsl:import href="XSL/html/chunk.xsl"/>

<!-- override default cellspacing value -->

  <xsl:variable name="html.cellspacing">0</xsl:variable>

<!-- vinodk: Not sure if this is needed                   -->
  <xsl:output media-type="text/html" encoding="UTF-8"/>

<!-- emmar: will produce valid HTML (won't close IMG, BR and HR tags) -->
  <xsl:output method="html" 
              version="4.01" />

<!-- emmar: set params for output -->
  <xsl:param name="chunker.output.doctype-public">-//W3C//DTD HTML 4.01 Transitional//EN</xsl:param>
  <xsl:param name="chunker.output.doctype-system">http://www.w3.org/TR/html4/loose.dtd"</xsl:param>
  <xsl:param name="chunker.output.encoding">UTF-8</xsl:param>
  <xsl:param name="html.stylesheet">openacs.css</xsl:param>


  <xsl:variable name="generate.index">1</xsl:variable>

<!-- vinodk: narrower TOC's, use chunker (?), pretty file names      -->
  <xsl:variable name="toc.section.depth">1</xsl:variable>
  <xsl:variable name="using.chunker">1</xsl:variable>
  <xsl:variable name="use.id.as.filename">1</xsl:variable>

  <xsl:variable name="chunk.first.sections">1</xsl:variable>


<!-- vinodk: Add our logo to header                   -->
  <xsl:template name="header.navigation">
    <xsl:param name="prev" select="/foo"/>
    <xsl:param name="next" select="/foo"/>
    <xsl:variable name="home" select="/*[1]"/>
    <xsl:variable name="up" select="parent::*"/>

    <xsl:if test="$suppress.navigation = '0'">
      <div class="navheader">
        <a href="http://openacs.org"><img src="/doc/images/alex.jpg" style="border:0" alt="Alex logo"/></a>
        <table width="100%" summary="Navigation header" border="0">
          <tr>
            <td width="20%" align="left">
              <xsl:if test="count($prev)>0">
                <a accesskey="p">
                  <xsl:attribute name="href">
                    <xsl:call-template name="href.target">
                      <xsl:with-param name="object" select="$prev"/>
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="gentext.nav.prev"/>
                </a>
              </xsl:if>
              <xsl:text> </xsl:text>
            </td>
            <th width="60%" align="center">
              <xsl:choose>
                <xsl:when test="count($up) > 0 and $up != $home">
                  <xsl:apply-templates select="$up" mode="object.title.markup"/>
                </xsl:when>
                <xsl:otherwise> </xsl:otherwise>
              </xsl:choose>
            </th>
            <td width="20%" align="right">
              <xsl:text> </xsl:text>
              <xsl:if test="count($next)>0">
                <a accesskey="n">
                  <xsl:attribute name="href">
                    <xsl:call-template name="href.target">
                      <xsl:with-param name="object" select="$next"/>
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="gentext.nav.next"/>
                </a>
              </xsl:if>
            </td>
          </tr>
        </table>
        <hr/>
      </div>
    </xsl:if>
  </xsl:template>
  
  
<!-- vinodk: Add our emails to footer                   -->
  <xsl:template name="footer.navigation">
    <xsl:param name="prev" select="/foo"/>
    <xsl:param name="next" select="/foo"/>
    <xsl:variable name="home" select="/*[1]"/>
    <xsl:variable name="up" select="parent::*"/>
    
    <xsl:if test="$suppress.navigation = '0'">
      <div class="navfooter">
        <hr/>
        <table width="100%" summary="Navigation footer">
          <tr>
            <td width="40%" align="left">
              <xsl:if test="count($prev)>0">
                <a accesskey="p">
                  <xsl:attribute name="href">
                    <xsl:call-template name="href.target">
                      <xsl:with-param name="object" select="$prev"/>
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="gentext.nav.prev"/>
                </a>
              </xsl:if>
              <xsl:text> </xsl:text>
            </td>
            <td width="20%" align="center">
              <xsl:choose>
                <xsl:when test="$home != .">
                  <a accesskey="h">
                    <xsl:attribute name="href">
                      <xsl:call-template name="href.target">
                        <xsl:with-param name="object" select="$home"/>
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:call-template name="gentext.nav.home"/>
                  </a>
                </xsl:when>
                <xsl:otherwise> </xsl:otherwise>
              </xsl:choose>
            </td>
            <td width="40%" align="right">
              <xsl:text> </xsl:text>
              <xsl:if test="count($next)>0">
                <a accesskey="n">
                  <xsl:attribute name="href">
                    <xsl:call-template name="href.target">
                      <xsl:with-param name="object" select="$next"/>
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="gentext.nav.next"/>
                </a>
              </xsl:if>
            </td>
          </tr>
          
          <tr>
            <td width="40%" align="left">
              <xsl:apply-templates select="$prev" mode="object.title.markup"/>
              <xsl:text> </xsl:text>
            </td>
            <td width="20%" align="center">
              <xsl:choose>
                <xsl:when test="count($up)>0">
                  <a accesskey="u">
                    <xsl:attribute name="href">
                      <xsl:call-template name="href.target">
                        <xsl:with-param name="object" select="$up"/>
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:call-template name="gentext.nav.up"/>
                  </a>
                </xsl:when>
                <xsl:otherwise> </xsl:otherwise>
              </xsl:choose>
            </td>
            <td width="40%" align="right">
              <xsl:text> </xsl:text>
              <xsl:apply-templates select="$next" mode="object.title.markup"/>
            </td>
          </tr>
        </table>
        <hr/>
        <address>
          <a>
            <xsl:attribute name="href">
              <xsl:text>mailto:docs@openacs.org</xsl:text>
            </xsl:attribute>
            <xsl:text>docs@openacs.org</xsl:text>
          </a>
        </address>
      </div>
      <!-- vinodk: Add a name tag so we can point directly to 
                   the comments from other pages -->
      <a>
        <xsl:attribute name="name">
          <xsl:text>comments</xsl:text>
        </xsl:attribute>
      </a>
      <!-- vinodk: Include a link back to canonical docs on openacs.org
                   Will need to remove this section on the actual
                   openacs.org website -->
      <!-- <center>
        <a>
          <xsl:attribute name="href">
            <xsl:text>http://openacs.org/doc/current/</xsl:text>
                    <xsl:call-template name="href.target">
                      <xsl:with-param name="object" select="."/>
                    </xsl:call-template>
            <xsl:text>#comments</xsl:text>
          </xsl:attribute>
          <xsl:text>View comments on this page at openacs.org</xsl:text>
        </a>
      </center> -->
    </xsl:if>
  </xsl:template>
  
<!-- vinodk: for some reason, chunk.xsl doesn't have a template 
                  for authorblurb. Also add doc disclaimer.   -->
  <xsl:template match="authorblurb">
    <div class="{name(.)}">
      <xsl:apply-templates/>
        <xsl:text>
          OpenACS docs are written by the named authors, and may be edited
          by OpenACS documentation staff.
        </xsl:text>
    </div>
  </xsl:template>
  
  
  <xsl:template name="html.head">
    <xsl:param name="prev" select="/foo"/>
    <xsl:param name="next" select="/foo"/>
    <xsl:variable name="home" select="/*[1]"/>
    <xsl:variable name="up" select="parent::*"/>
    
    <head>
      <xsl:call-template name="head.content"/>
      <xsl:call-template name="user.head.content"/>
      
      <xsl:if test="$home">
        <link rel="home">
          <xsl:attribute name="href">
            <xsl:call-template name="href.target">
              <xsl:with-param name="object" select="$home"/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:attribute name="title">
            <xsl:apply-templates select="$home"
              mode="object.title.markup.textonly"/>
          </xsl:attribute>
        </link>
      </xsl:if>
      
      <xsl:if test="$up">
        <link rel="up">
          <xsl:attribute name="href">
            <xsl:call-template name="href.target">
              <xsl:with-param name="object" select="$up"/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:attribute name="title">
            <xsl:apply-templates select="$up" mode="object.title.markup.textonly"/>
          </xsl:attribute>
        </link>
      </xsl:if>
      
      <xsl:if test="$prev">
        <link rel="previous">
          <xsl:attribute name="href">
            <xsl:call-template name="href.target">
              <xsl:with-param name="object" select="$prev"/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:attribute name="title">
            <xsl:apply-templates select="$prev" mode="object.title.markup.textonly"/>
          </xsl:attribute>
        </link>
      </xsl:if>
      
      <xsl:if test="$next">
        <link rel="next">
          <xsl:attribute name="href">
            <xsl:call-template name="href.target">
              <xsl:with-param name="object" select="$next"/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:attribute name="title">
            <xsl:apply-templates select="$next" mode="object.title.markup.textonly"/>
          </xsl:attribute>
        </link>
      </xsl:if>

    </head>
  </xsl:template>

<!-- vinodk: make phrase a "div" tag instead of "span" -->
  <xsl:template match="phrase">
    <div>
      <xsl:if test="@role and $phrase.propagates.style != 0">
        <xsl:attribute name="class">
          <xsl:value-of select="@role"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:call-template name="anchor"/>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

<!-- custom stuff to add better css hooks -->
<xsl:template match="guibutton">
  <span class="guibutton">
    <xsl:call-template name="inline.charseq"/>
  </span>	
</xsl:template>

<xsl:template match="guilabel">
  <span class="guilabel">
    <xsl:call-template name="inline.charseq"/>
  </span>	
</xsl:template>

<xsl:template match="action">
    <span class="action"><xsl:call-template name="inline.charseq"/></span>
</xsl:template>

<xsl:template match="replaceable">
  <span class="replaceable">
    <xsl:call-template name="inline.charseq"/>
  </span>	
</xsl:template>

<xsl:template match="accel">
  <u>
    <xsl:call-template name="inline.charseq"/>
  </u>	
</xsl:template>


<!-- override the default processing of segmented lists to get
prettier tables -->

<xsl:template match="segmentedlist">
  <xsl:variable name="presentation">
    <xsl:call-template name="dbhtml-attribute">
      <xsl:with-param name="pis"
                      select="processing-instruction('dbhtml')"/>
      <xsl:with-param name="attribute" select="'list-presentation'"/>
    </xsl:call-template>
  </xsl:variable>

  <div class="{name(.)}">
    <xsl:call-template name="anchor"/>

    <xsl:choose>
      <xsl:when test="$presentation = 'req-table'">
        <xsl:apply-templates select="." mode="seglist-req-table"/>
      </xsl:when>
      <xsl:when test="$presentation = 'table'">
        <xsl:apply-templates select="." mode="seglist-table"/>
      </xsl:when>
      <xsl:when test="$presentation = 'list'">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="$segmentedlist.as.table != 0">
        <xsl:apply-templates select="." mode="seglist-table"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </div>
</xsl:template>

<xsl:template match="segmentedlist" mode="seglist-req-table">
  <xsl:variable name="table-summary">
    <xsl:call-template name="dbhtml-attribute">
      <xsl:with-param name="pis"
                      select="processing-instruction('dbhtml')"/>
      <xsl:with-param name="attribute" select="'table-summary'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="list-width">
    <xsl:call-template name="dbhtml-attribute">
      <xsl:with-param name="pis"
                      select="processing-instruction('dbhtml')"/>
      <xsl:with-param name="attribute" select="'list-width'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:apply-templates select="title"/>

  <table border="1" cellpadding="3" cellspacing="0" width="90%">
  <tr><th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th></tr>
    <xsl:if test="$list-width != ''">
      <xsl:attribute name="width">
        <xsl:value-of select="$list-width"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$table-summary != ''">
      <xsl:attribute name="summary">
        <xsl:value-of select="$table-summary"/>
      </xsl:attribute>
    </xsl:if>
    <thead>
      <tr>
        <xsl:call-template name="tr.attributes">
          <xsl:with-param name="row" select="segtitle[1]"/>
          <xsl:with-param name="rownum" select="1"/>
        </xsl:call-template>
        <xsl:apply-templates select="segtitle" mode="seglist-table"/>
      </tr>
    </thead>
    <tbody>
      <xsl:apply-templates select="seglistitem" mode="seglist-table"/>
    </tbody>
  </table>
</xsl:template>



</xsl:stylesheet>

