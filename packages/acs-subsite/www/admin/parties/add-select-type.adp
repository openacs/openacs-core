<master>
<property name="context">@context;noquote@</property>
<property name="title">Select specific @object_type_pretty_name;noquote@ type</property>

<blockquote>

What type of @object_type_pretty_name@ do you want to create?

<p>

<multiple name="object_types">

  @object_types.indent;noquote@ 

  <if @object_types.valid_p@ eq 1>
  <a href="@this_url@?@export_url_vars@&@object_type_variable@=@object_types.object_type_enc@">@object_types.pretty_name@</a>
  </if>
  <else>
  @object_types.pretty_name@
  </else>

  <br>

</multiple>

</blockquote>
