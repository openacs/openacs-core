<master src="../box-master">
  <property name="title"><a href="/community/companies/">@title@</a></property>

<multiple name=companies>
  <if @companies.rownum@ le @n_companies@>
    <p>
      <span id="title"><b><a href="@companies.url@">@companies.title@</b></a></span>
      <if @companies.description@ not nil>
	<span id="description"> - @companies.description@</span>
      </if>
    </p>
  </if>
</multiple>

<if @companies:rowcount@ gt @n_companies@>
  <span id="more"><a href="companies">more companies</a>...</span>
</if>
