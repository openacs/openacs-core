<master src="../box-master">
<property name="title"><a href="/community/hosting/">@title@</a></property>

<multiple name=hosting>
<if @hosting.rownum@ le @n_hosting@>
  <span id="title"><a href="@hosting.url@">@hosting.title@</a></span>
  <if @hosting.description@ not nil>
  <span id="description"> - @hosting.description@</span>
  </if>
  <br><br>
</if>
</multiple>

<if @hosting:rowcount@ gt @n_hosting@>
  <span id="more"><a href="/community/hosting/">more hosting alternatives</a>...</span>
</if>
