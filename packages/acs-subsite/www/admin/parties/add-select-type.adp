<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Select specific @object_type_pretty_name;noquote@ type</property>

<blockquote>

<p>
What type of <strong>@object_type_pretty_name@</strong> do you want to create?

<p>

<multiple name="object_types">

  @object_types.indent;noquote@ 

  <if @object_types.valid_p;literal@ true>
  <a href="@this_url@?@export_url_vars@&amp;@object_type_variable@=@object_types.object_type_enc@">@object_types.pretty_name@</a>
  </if>
  <else>
  @object_types.pretty_name@
  </else>

  <br>

</multiple>

</blockquote>
