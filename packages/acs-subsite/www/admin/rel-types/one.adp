<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Relationship Type "@rel_type_pretty_name;noquote@"</property>
				   
<h4>Relations of this type</h4>

<ul>
 <if @rels:rowcount@ eq 0>
    <li>(none)</li>
 </if><else>
  <multiple name="rels">
   <if @rels.rownum@ eq 26>
    <br> ... ...
    <li> <a href="rels-list?rel_type=@rel_type_enc@">Display all relations</a>
   </if>
   <else>
    <li> <a href="../relations/one?rel_id=@rels.rel_id@">@rels.name@</a>
    </li>
   </else>
  </multiple>
 </else>
</ul>


<h4>Attributes of this type of relationship</h4>

<ul>
  <if @attributes:rowcount@ eq 0>
    <li>(none)</li>
  </if><else>
   <multiple name="attributes">
    <li> <a href="../attributes/one?attribute_id=@attributes.attribute_id@&amp;return_url=@return_url_enc@">@attributes.pretty_name@</a> 
    </li>
   </multiple>
  </else>
  <if @dynamic_p;literal@ true> 
    <li> <a href="../attributes/add?object_type=@rel_type_enc@&amp;return_url=@return_url_enc@">Add an attribute</a></li>
  </if><else>
    <li> Attributes can only be added by programmers since this object type is not dynamically created</li>
  </else>
</ul>


<h4>Properties of this type of relationship</h4>

<ul>
  <li> <strong>Side One:</strong>
  <ul>
    <li> Object Type: <a href="../object-types/one?object_type=@properties.object_type_one@">@properties.object_type_one_pretty_name@</a>
    <li> Role: <a href="roles/one?role=<%=[ad_urlencode $properties(role_one)]%>">@properties.role_one_pretty_name@</a>

<if @properties.min_n_rels_one@ nil>
    <li> Min number of relations: Unspecified
</if><else>
    <li> Min number of relations: @properties.min_n_rels_one@
</else>

<if @properties.max_n_rels_two@ nil>
    <li> Max number of relations: Unspecified
</if><else>
    <li> Max number of relations: @properties.max_n_rels_one@
</else>
  </ul>

  <p><li> <strong>Side Two:</strong>
  <ul>
    <li> Object Type: <a href="../object-types/one?object_type=@properties.object_type_two@">@properties.object_type_two_pretty_name@</a>
    <li> Role: <a href="roles/one?role=<%=[ad_urlencode $properties(role_two)]%>">@properties.role_two_pretty_name@</a>

<if @properties.min_n_rels_one@ nil>
    <li> Min number of relations: Unspecified
</if><else>
    <li> Min number of relations: @properties.min_n_rels_two@
</else>

<if @properties.max_n_rels_two@ nil>
    <li> Max number of relations: Unspecified
</if><else>
    <li> Max number of relations: @properties.max_n_rels_two@
</else>
  </ul>


</ul>


<h4>Administration</h4>

<ul>

  <li> <a href="new-2?supertype=@rel_type_enc@">Create subtype</a>

<if @dynamic_p;literal@ true> 
  <li> <a href="delete?rel_type=@rel_type_enc@">Delete this relationship type</a>
</if>

</ul>

