<master src="blank-master">
  <property name="title">@title;noquote@</property>
  <if @header_stuff@ not nil><property name="header_stuff">@header_stuff;noquote@</property></if>
  <if @focus@ not nil><property name="focus">@focus;noquote@</property></if>
  <if @doc_type@ not nil><property name="doc_type">@doc_type;noquote@</property></if>

<include src="login-status" />

<if @body_start_include@ not nil>
<include src="@body_start_include@" />
</if>

<h1>@title;noquote@</h1>
@context_bar;noquote@
<hr />
<slave>
<if @curriculum_bar_p@ true>
<include src="/packages/curriculum/lib/bar" />
</if>
<hr />
<address><a href="mailto:@signatory@">@signatory@</a></address>
