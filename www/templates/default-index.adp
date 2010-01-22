<master>
<property name="title">@pa.title;noquote@</property>
<property name="context_bar">@pa.context_bar;noquote@</property>

<if @pa.content@ not nil>
@pa.content;noquote@
</if>

<if @content_items:rowcount@ gt 0>
<ul>
<multiple name="content_items">
<li>
<a href="@content_items.url@">@content_items.title;noquote@</a>
<if @content_items.description@ not nil>
 - @content_items.description;noquote@
</if>
</li>
</multiple>
</ul>
</if>

<if @comments_link@ not nil>
  @comments;noquote@
  <p>
    @comments_link;noquote@
  </p>
</if>
