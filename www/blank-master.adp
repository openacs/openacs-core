@doc_type;noquote@
<html>
  <head>
    <meta name="generator" content="OpenACS version @openacs_version@">
    <title>@title;noquote@</title>
    <multiple name="header_links">
      <link rel="@header_links.rel@" type="@header_links.type@" href="@header_links.href@" media="@header_links.media@">
    </multiple>

    <script src="/resources/acs-subsite/core.js" language="javascript"></script>
    <textarea id="holdtext" style="display: none;"></textarea>

    @header_stuff;noquote@
  </head>
  <body<multiple name=attribute> @attribute.key@="@attribute.value@"</multiple>>
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
