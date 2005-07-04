@doc_type;noquote@
<html>
  <head>
    <title>@title;noquote@</title>
    <meta name="generator" content="OpenACS version @openacs_version@">
    <if @developer_support_p@ true>
      <link rel="stylesheet" type="text/css" href="/resources/acs-developer-support/acs-developer-support.css" media="all">
    </if>
    <multiple name="header_links">
      <link rel="@header_links.rel@" type="@header_links.type@" href="@header_links.href@" media="@header_links.media@">
    </multiple>

    <if @acs_blank_master__htmlareas@ not nil><script type="text/javascript" src="/resources/acs-templating/rte/richtext.js"></script></if>

    <script type="text/javascript" src="/resources/acs-subsite/core.js"></script>

    @header_stuff;noquote@
  </head>
  <body<multiple name="attribute"> @attribute.key@="@attribute.value@"</multiple>>
  <div><textarea id="holdtext" style="display: none;" rows="1" cols="1"></textarea></div>
  <if @acs_blank_master__htmlareas@ not nil>
    <script type="text/javascript"><!--
      //Usage: initRTE(imagesPath, includesPath, cssFile)
      initRTE("/resources/acs-templating/rte/images/", "/resources/acs-templating/rte/", "");
      // --></script></if>


    <if @dotlrn_toolbar_p@ true>
      <include src="/packages/dotlrn/lib/toolbar">
    </if>
    <if @developer_support_p@ true>
      <include src="/packages/acs-developer-support/lib/toolbar">
    </if>

    <slave>

    <if @developer_support_p@ true>
      <include src="/packages/acs-developer-support/lib/footer">
    </if>
    <if @translator_mode_p@ true>
      <include src="/packages/acs-lang/lib/messages-to-translate">
    </if>
  </body>
</html>
