<html>
<head>
	<title>Package: @package_name@</title>
</head>

<body bgcolor="#FFFFFF">

<h2>@package_name@</h2>
<p>
<a href="../index.html">Content Repository</a> : @package_name@
<hr>

<ul>
  <if @info.comment@ not nil>
    <li><a href="#overview">Overview</a></li>
  </if>
  <if @info.see@ not nil>
    <li><a href="#related">Related Objects</a></li>
  </if>
  <li><a href="#api">API</a></li>
</ul>
<p>&nbsp;</p>

<if @info.comment@ not nil>
<a name="overview"><h3>Overview</h3></a>
<p>@info.comment@</p>
<p>&nbsp;</p>
</if>

<if @info.see@ not nil>
<a name="related"><h3>Related Objects</h3></a>
See also: @info.see@
<p>&nbsp;</p>
</if>

<a name="api"><h3>API</h3></a>
<multiple name=methods>
  <include src=method package=@package_name;noquote@ method=@methods.name;noquote@>
  <p>&nbsp;</p>
</multiple>

Last Modified: $Id$

</body>
</html>
