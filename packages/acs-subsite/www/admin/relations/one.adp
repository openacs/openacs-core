<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">One relation</property>
				   
<h3>Attributes</h3>

<ul>
 <if @attributes:rowcount@ eq "0">
  <li> <em>There are no attributes for relations of this type</em> </li>
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
</ul>


<h3>Properties</h3>

<ul>
 <li> Relationship type: <a href="../rel-types/one?rel_type=@rel.rel_type_enc@">@rel.rel_type_pretty_name@</a> </li>
 <li> Object 1 (@rel.role_one_pretty_name@): 
      <if @subsite_group_id@ eq @rel.object_id_one@>
      <a href="../groups/index?view_by=rel_type">@rel.object_id_one_name@</a> </li>
      </if>
      <else>
      <a href="../groups/one?group_id=@rel.object_id_one@">@rel.object_id_one_name@</a> </li>
      </else>
 <li> Object 2 (@rel.role_two_pretty_name@): 
      <a href="../parties/one?party_id=@rel.object_id_two@">@rel.object_id_two_name@</a> </li>
</ul>

<if @admin_p@ true or @delete_p@ true>
<p><h3>Administration</h3>
 <ul>
  <if @admin_p@ true and @member_state@ ne "">
        <li> Member State:
      <form method="post" action="change-member-state">
    	<div>
      <input type="hidden" name="return_url" value="@QQreturn_url@">
      <input type="hidden" name="rel_id" value="@rel_id@">
      <select name="member_state">
      <list name="possible_member_states">
          <option value="@possible_member_states:item@"
             <if @possible_member_states:item@ eq @member_state@>
               selected
             </if>
          >
          @possible_member_states:item@
      </list>
      </select>
      <input type="submit" value="Change Status">
      </div>
      </form>
      </li>
  </if>
  <li> <a href="remove?rel_id=@rel_id@">Remove this relation</a> </li>
 </ul>
</if>

<if @object_two_read_p;literal@ true>
    <h3>About @rel.object_id_two_name@</h3>
    
    <ul>
     <if @object_two_attributes:rowcount@ eq "0">
      <li> <em>There are no attributes for parties of this type</em> </li>
     </if>
     <else>
      <multiple name="object_two_attributes">
       <li> @object_two_attributes.pretty_name@: 
       <if @object_two_attributes.value@ nil>
         <em>(no value)</em>
       </if><else>
          @object_two_attributes.value@
       </else>
       <if @object_two_write_p;literal@ true>
         (<a href="../attributes/edit-one?@object_two_attributes.export_vars@">edit</a>) 
       </if>
       </li>
      </multiple>
     </else>
    </ul>

    <ul>
    <li><a href="../parties/one?party_id=@rel.object_id_two@">more</a> about @rel.object_id_two_name@
    </ul>
</if>
