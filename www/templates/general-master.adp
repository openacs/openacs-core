<master src="/www/blank-master">
  <if @title@ not nil>
    <property name="title">@title;noquote@</property>
  </if>
  <if @signatory@ not nil>
    <property name="signatory">@signatory;noquote@</property>
  </if>
  <if @focus@ not nil>
    <property name="focus">@focus;noquote@</property>
  </if>
  <property name="header_stuff">
    <link rel="stylesheet" type="text/css" href="@css_url@" media="all">
    @header_stuff;noquote@
  </property>

<!-- START HEADER -->

<div class="header">
<include src="widgets/header">
</div>

<!-- END HEADER -->
<if @title@ not nil and @notitle@ nil>
<h2>@title;noquote@</h2>
</if>
<if @context_bar@ not nil>
<span class="context">
@context_bar;noquote@
<hr noshade />
</if>
<slave>



<!-- START FOOTER -->

<div class="footer">
<include src="widgets/footer" signatory="@signatory@">
</div>

<!-- END FOOTER -->



<if @etp_link@ not nil>
<!-- START ETP LINK -->

<span class="etp-link">@etp_link;noquote@</span>

<!-- END ETP LINK -->
</if>
