<ul>
<if @rels:rowcount@ eq 0>
  <li>There are no allowable relationship types for this group</li>
</if>
<else>
 <multiple name="rels">
  <p><li> <b>@rels.role_pretty_plural@ (@rels.rel_type_pretty_name@)</b> </li>
  <group column=rel_type>
    <if @rels.num_rels@ nil>
      <ul>
      <li> There are currently no @rels.role_pretty_plural@ </li>
      </ul>
    </if><else>
      <if @rels.num_rels@ gt 10>
        <ul>
        <li> <a href=elements-display?group_id=@group_id@&rel_type=@rels.rel_type@>Display all @rels.num_rels@ @rels.role_pretty_plural@</a> </li>
        </ul>
      </if><else>
        <br>
	<include src="elements-display-list" group_id="@group_id;noquote@" rel_type="@rels.rel_type;noquote@" return_url_enc=@return_url_enc;noquote@ member_state="approved">
      </else>
    </else>
  </group>

  <ul>
  <p><li> Administration</li>
   <ul>
    <if @create_p@ eq 1 and @rels.rel_type_valid_p@ eq 1>
      <li> <a href=../relations/add?group_id=@group_id@&rel_type=@rels.rel_type@&return_url=@return_url_enc@>Add @rels.role_pretty_name@</a> </li>
    </if>
    
    <li> Relational segment: 
    <if @rels.segment_id@ nil>
      <em>none</em> (<a href=../rel-segments/new?group_id=@group_id@&rel_type=@rels.rel_type@&return_url=@return_url_enc@>create segment</a>) </li>
    </if>
    <else>
      <a href="../rel-segments/one?segment_id=@rels.segment_id@">(@rels.segment_name@)</a> </li>
    </else>
   <if @admin_p@ eq "1">
      <li> <a href=rel-type-remove?group_rel_id=@rels.group_rel_id@>Remove this relationship type</a> </li>
   </if>
   </ul>
  </ul>	

 </multiple>
</else>

  <p><li> <a href="rel-type-add?group_id=@group_id@">Add a permissible relationship type</a> </li>
</ul>
