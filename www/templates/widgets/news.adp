<master src="../box-master">
<property name="title"><a href="/news/">@title@</a></property>

<multiple name=news_items>
<if @news_items.rownum@ le @n_news_items@>
  @news_items.pretty_publish_date@<br>
  <span class="item"><a href="/news/item?item_id=@news_items.item_id@">@news_items.publish_title@</a></span>
  <br>
</if>
</multiple>

<if @news_items:rowcount@ eq 0>
<p>  There are no recent news items. </p>
<p>  <a href="/news/?view=archive">Read</a> archived news items.</p>
</if>

<if @news_items:rowcount@ gt @n_news_items@>
  <span class="more"><a href="/news/">more news</a>...</span>
</if>