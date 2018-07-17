<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">@attribute.pretty_name;literal@</property>
	
<strong>Properties:</strong>			   
<ul>
<multiple name="attr_props">
  <li> <strong>@attr_props.key@:</strong> @attr_props.value@
</multiple>
</ul>

<if @attribute.datatype@ eq "enumeration">
  <p><strong>Possible values:</strong>
  <ul>
  <if @enum_values:rowcount;literal@ eq 0>
    <li> <em>(none)</em>
  </if>
  <else>
  <multiple name="enum_values">
    <li> @enum_values.pretty_name@ 
         (<a href="value-delete?attribute_id=@attribute_id@&amp;enum_value=<%=[ad_urlencode $enum_values(enum_value)]%>">delete</a>)
  </multiple
  </else>
    <p><li><a href="enum-add?@url_vars@">Add value</a>
  </ul>
  
</if>

<p><strong>Administration:</strong>
<ul>

<if @dynamic_p;literal@ true>
  <li><a href="delete?@url_vars@">Delete this attribute</a>
</if><else>
  <li>  This attribute can only be administered by programmers as it does not belong to a dynamically created object.
</else>

</ul>
