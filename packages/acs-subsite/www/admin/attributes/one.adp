<master>
<property name="context">@context;noquote@</property>
<property name="title">@attribute.pretty_name;noquote@</property>
	
<b>Properties:</b>			   
<ul>
<multiple name="attr_props">
  <li> <b>@attr_props.key@:</b> @attr_props.value@
</multiple>
</ul>

<if @attribute.datatype@ eq "enumeration">
  <p><b>Possible values:</b>
  <ul>
  <if @enum_values:rowcount@ eq 0>
    <li> <em>(none)</em>
  </if>
  <else>
  <multiple name="enum_values">
    <li> @enum_values.pretty_name@ 
         (<a href=value-delete?attribute_id=@attribute_id@&enum_value=<%=[ad_urlencode $enum_values(enum_value)]%>>delete</a>)
  </multiple
  </else>
    <p><li><a href=enum-add?@url_vars@>Add value</a>
  </ul>
  
</if>

<p><b>Administration:</b>
<ul>

<if @dynamic_p@ eq "t">
  <li><a href=delete?@url_vars@>Delete this attribute</a>
</if><else>
  <li>  This attribute can only be administered by programmers as it does not belong to a dynamically created object.
</else>

</ul>
