@doc_type;noquote@
<html>
<head>
<title>@title;noquote@</title>
@header_stuff;noquote@
<multiple name="header_links">
  <link rel="@header_links.rel@" type="@header_links.type@" href="@header_links.href@" media="@header_links.media@">
</multiple>
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
