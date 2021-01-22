<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">@group_name;literal@</property>

<h2>Manage Group: @group_name@</h2>
Group Type: @group_type_pretty_name@

<h3>Attributes</h3>

<ul>
 <if @attributes:rowcount@ eq "0">
  <li> <em>There are no attributes for groups of this type</em> </li>
 </if>
 <else>
  <multiple name="attributes">
   <li> @attributes.pretty_name@: 
   <if @attributes.value@ nil>
     <em>(no value)</em>
   </if><else>
      @attributes.value@
   </else>
   <if @write_p;literal@ true>
     (<a href="../attributes/edit-one?@attributes.export_vars@">edit</a>) 
   </if>
   </li>
  </multiple>
 </else>
 <li> Join Policy: @join_policy@
     <if @admin_p;literal@ true>
         (<a href="change-join-policy?return_url=@return_url_enc@&amp;group_id=@group_id@">edit</a>)
     </if>
 <if @category_url@ not nil>
  <li>Category trees: @category_trees@
      (<a href="@category_url@cadmin/object-map?object_id=@group_id@">edit</a>)
  </li>
 </if>
</ul>

 
<h3>Permissible relationship types (subtypes of membership or composition rels)</h3>
<include src="elements-by-rel-type" group_id="@group_id;literal@">

<if @admin_p;literal@ true>
  <h3>Extreme Actions</h3>
  <ul>
    <li> <a href="delete?group_id=@group_id@" class="button">Nuke this group</a>
  </ul>
</if>

