<master src="../box-master">
<property name="title"><a href="/community/sites/">@title@</a></property>

<multiple name=sites>
<if @sites.rownum@ le @n_sites@>
  <span id="title"><a href="@sites.url@">@sites.title@</a></span>
  <if @sites.description@ not nil>
  <span id="description"> - @sites.description@</span>
  </if>
  <br><br>
</if>
</multiple>

  <span id="more"><a href="sites/">more sites</a>...</span>






