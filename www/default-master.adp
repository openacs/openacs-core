@doc_type;noquote@
<html>
<head>
<title>@title;noquote@</title>
@header_stuff;noquote@
</head>
<body<multiple name=attribute> @attribute.key@="@attribute.value@"</multiple>>
<include src="login-status" />

<if @body_start_include@ not nil>
<include src="@body_start_include@" />
</if>

<h1>@title;noquote@</h1>
@context_bar;noquote@
<hr />
<slave>
<if @curriculum_bar_p@>
<include src="/packages/curriculum/lib/bar" />
</if>
<hr />
<address><a href="mailto:@signatory@">@signatory@</a></address>
@ds_link;noquote@
</body>
</html>
