<master>
<property name="title">OpenACS Projects</property>
<property name="context">@context@</property>

<if @pa.content@ not nil>
@pa.content;noquote@
</if>

<if @site_nodes:rowcount@ gt 0>
<ul>
<multiple name="site_nodes">
<li><a href="@site_nodes.url@">@site_nodes.name@</a></li>
</multiple>
</ul>
</if>

    <multiple name="content_items">
<b><a href="@content_items.url@">@content_items.title@</a></b>
<if @content_items.description@ not nil>
 - @content_items.description;noquote@
</if>
<br>
</multiple>

