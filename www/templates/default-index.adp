<master>
<property name="title">@pa.title@</property>
<property name="context_bar">@pa.context_bar;noquote@</property>

<if @pa.content@ not nil>
@pa.content@
</if>

<blockquote><p>
<multiple name="content_items">
<b><a href="@content_items.url@">@content_items.title@</a></b>
<if @content_items.description@ not nil>
 - @content_items.description@
</if>
<br><br>
</multiple>
</p>
</blockquote>
</p>



<if @comments_link@ not nil>
  @comments@
  <p>
    @comments_link@
  </p>
</if>
