<master>
<property name="title">@pa.title;noquote@</property>
<property name="context_bar">@pa.context_bar;noquote@</property>

<if @pa.content@ not nil>
@pa.content;noquote@
</if>

<blockquote><p>
<multiple name="content_items">
<b><a href="@content_items.url@">@content_items.title;noquote@</a></b>
<if @content_items.description@ not nil>
 - @content_items.description;noquote@
</if>
<br><br>
</multiple>
</p>
</blockquote>
</p>



<if @comments_link@ not nil>
  @comments;noquote@
  <p>
    @comments_link;noquote@
  </p>
</if>
