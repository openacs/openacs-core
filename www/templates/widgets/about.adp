<master src="../box-master">
<property name="title"><a href="/about/">@title@</a></property>

<multiple name=about>
  <p class="item"><a href="about/@about.url@">@about.title;noquote@</a>
  <if @about.description@ not nil>
  <span class="description"> - @about.description;noquote@</span>
  </if>
</p>
</multiple>
