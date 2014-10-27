@doc.type;literal@
<html<if @doc.lang@ not nil> lang="@doc.lang;literal@"</if>>
<head>
    <title<if @doc.title_lang@ not nil and @doc.title_lang;literal@ ne @doc.lang;literal@> lang="@doc.title_lang;literal@"</if>>@doc.title;noquote@</title>

<multiple name="meta">    <meta<if @meta.http_equiv@ not nil> http-equiv="@meta.http_equiv;literal@"</if><if @meta.name@ not nil> name="@meta.name;noquote@"</if><if @meta.scheme@ not nil> scheme="@meta.scheme;noquote@"</if><if @meta.lang@ not nil and @meta.lang;literal@ ne @doc.lang;literal@> lang="@meta.lang;literal@"</if> content="@meta.content@">
</multiple>
<multiple name="link">    <link rel="@link.rel;literal@" href="@link.href;literal@"<if @link.lang@ not nil and @link.lang;literal@ ne @doc.lang;literal@> lang="@link.lang;literal@"</if><if @link.title@ not nil> title="@link.title;noquote@"</if><if @link.type@ not nil> type="@link.type;literal@"</if><if @link.media@ not nil> media="@link.media;literal@"</if>>
</multiple>

<multiple name="___style"> <style type="@___style.type;literal@" <if @___style.lang@ not nil and @___style.lang;literal@ ne @doc.lang;literal@> lang="@___style.lang;literal@"</if><if @___style.title@ not nil> title="@___style.title;literal@"</if><if @___style.media@ not nil> media="@___style.media;literal@"</if>>@___style.style;literal@
</style>
</multiple>

<comment>
   These two variables have to be set before the XinhaCore.js is loaded. To 
   enforce the order, it is put here.
</comment>
<if @::acs_blank_master__htmlareas@ defined and @::xinha_dir@ defined and @::xinha_lang@ defined>
<script type="text/javascript">
_editor_url = "@::xinha_dir;literal@"; 
_editor_lang = "@::xinha_lang;literal@";
</script>
</if>

<multiple name="headscript">   <script type="@headscript.type;literal@"<if @headscript.src@ not nil> src="@headscript.src;literal@"</if><if @headscript.charset@ not nil> charset="@headscript.charset;literal@"</if><if @headscript.defer@ not nil> defer="@headscript.defer;literal@"</if><if @headscript.async@ not nil> async="@headscript.async;literal@"</if>><if @headscript.content@ not nil>@headscript.content;noquote@</if></script>
</multiple>

<if @head@ not nil>@head;literal@</if>
</head>
<body<if @body.class@ not nil> class="@body.class;literal@"</if><if @body.id@ not nil> id="@body.id;literal@"</if><if @event_handlers@ not nil>@event_handlers;literal@</if>>
  @header;literal@
<slave>
  @footer;literal@
<multiple name="body_script">    <script type="@body_script.type;literal@"<if @body_script.src@ not nil> src="@body_script.src;literal@"</if><if @body_script.charset@ not nil> charset="@body_script.charset;literal@"</if><if @body_script.defer@ not nil> defer="@body_script.defer;literal@"</if><if @body_script.async@ not nil> async="@body_script.async;literal@"</if>><if @body_script.content@ not nil>@body_script.content;literal@</if></script>
</multiple>

</body>
</html>
