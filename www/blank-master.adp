@doc_type;noquote@
<html>
  <head>
    <meta name="generator" content="OpenACS version @openacs_version@">
    <title>@title;noquote@</title>
    <multiple name="header_links">
      <link rel="@header_links.rel@" type="@header_links.type@" href="@header_links.href@" media="@header_links.media@">
    </multiple>

    <if @acs_blank_master__htmlareas@ not nil>
      <script type="text/javascript" src="/resources/acs-templating/htmlarea/htmlarea.js"></script>
      <script type="text/javascript" src="/resources/acs-templating/htmlarea/lang/en.js"></script>
      <script type="text/javascript" src="/resources/acs-templating/htmlarea/dialog.js"></script>

      <style type="text/css">
      @import url(/resources/acs-templating/htmlarea/htmlarea.css);
      </style>
    </if>

    <script src="/resources/acs-subsite/core.js" language="javascript"></script>

    @header_stuff;noquote@
  </head>
  <body<multiple name="attribute"> @attribute.key@="@attribute.value@"</multiple>>

    <textarea id="holdtext" style="display: none;" rows="1" cols="1"></textarea>
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
