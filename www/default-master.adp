@doc_type;noquote@
<html>
<head>
<title>@title@</title>
@header_stuff@
</head>
<body<multiple name=attribute> @attribute.key@="@attribute.value@"</multiple>>
<include src="login-status" />

<if @body_start_include;noquote@ not nil>
<include src="@body_start_include;noquote@" />
</if>

<h1>@title@</h1>
@context_bar;noquote@
<hr />
<slave>
<if @curriculum_bar_p@>
<include src="/packages/curriculum/lib/bar" />
</if>
<hr />
<address><a href="mailto:@signatory@">@signatory@</a></address>
@ds_link@
</body>
</html>
