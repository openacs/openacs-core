<master src="../box-master">
<property name="title"><a href="/features/">@title@</a></property>

<multiple name=feature_items>
<if @feature_items.rownum@ le @n_feature_items@>
  <span class="title"><a href="@feature_items.url@">@feature_items.title@</a></span><br>
  <span class="item">@feature_items.description@</span>
  <br><br>
</if>
</multiple>

<if @feature_items:rowcount@ eq 0>
  There are no articles.
</if>

<if @feature_items:rowcount@ gt @n_feature_items@>
  <span class="more"><a href="/features">more articles</a>...</span>
</if>