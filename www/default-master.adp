<master src="blank-master">
  <property name="title">@title@</property>
  <property name="header_stuff">@header_stuff@</property>
  <property name="focus">@focus@</property>

<include src="login-status" />

<if @body_start_include@ not nil>
  <include src="@body_start_include@" />
</if>

<h1>@title@</h1>
@context_bar@
<hr />
<slave>

<hr />
<address><a href="mailto:@signatory@">@signatory@</a></address>
