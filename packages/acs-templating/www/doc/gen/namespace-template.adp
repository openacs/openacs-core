<html>
<head><title></title>
<link rel="stylesheet" Type="text/css" href="stylesheet.css" title="Style">
</head>
<body>


<h2>Namespace @info.name@</h2>
<if @info.author@ not nil>
&nbsp;&nbsp;<i>by @info.author@</i>
</if>
<blockquote>
@info.overview@
</blockquote>
<if @see:rowcount@ gt 0>
<p>Also see:
<dl>
  <multiple name=see>
    <dt>@see.type@
    <group column=type>
      <dd><a href="@see.url@">@see.name@</a>
    </group>
  </multiple>
</dl>
</if>

<p>

<h3>Method Summary</h3>
Listing of public methods:<br>
<blockquote>
<multiple name=public>
  <a href="#@public.name@">@public.name@</a><br>
</multiple>
<if @public:rowcount@ eq 0>
The namespace @info.name@ currently contains no public methods.
</if>
</blockquote>

<h3>Method Detail</h3>
<p align=right>
<font color=red>*</font> indicates required
</p>

<if @public:rowcount@ gt 0>
<b>Public Methods:</b><br>
</if>

<multiple name=public>
<include src=proc-template data=@public.data;noquote@>
<p>
</multiple>

<p>

<if @private:rowcount@ gt 0>
<b>Private Methods</b>:<br>
</if>
<multiple name=private>
<include src=proc-template data=@private.data;noquote@>
<p>
</multiple>

<p align=right>
<font color=red>*</font> indicates required
</p>

</body>
</html>








