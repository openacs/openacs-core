<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
       "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>@title@</title>
@header_stuff@
</head>
<body<multiple name=attribute> @attribute.key@="@attribute.value@"</multiple>>
<include src="login-status" />

<if @body_start_include@ not nil>
  <include src="@body_start_include@" />
</if>

<h1>@title@</h1>
@context_bar@
<hr />
<slave>

<hr />
<address><a href="mailto:@signatory@">@signatory@</a></address>
@ds_link@
</body>
</html>
