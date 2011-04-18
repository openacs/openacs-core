<ul>

<if @rels:rowcount@ eq 0>
  <li>There are no allowable relationship types for this group</li>
</if>

<else>
  <multiple name="rels">

    <li><strong>@rels.role_pretty_plural@ (@rels.rel_type_pretty_name@)</strong>

      <group column=rel_type>
        <if @rels.num_rels@ nil>
          <ul>
            <li> There are currently no @rels.role_pretty_plural@ </li>
          </ul>
        </if>
        <else>
          <if @rels.num_rels@ gt 10>
            <ul>
              <li><a href="@elements_display_url@">Display all @rels.num_rels@ @rels.role_pretty_plural@</a> </li>
            </ul>
          </if>
          <else>
            <br>
	        <include src="elements-display-list" group_id="@group_id;noquote@" rel_type="@rels.rel_type;noquote@" return_url_enc="@return_url_enc;noquote@" member_state="approved">
          </else>
        </else>
      </group>

      <ul>
        <li>#acs-subsite.Administration#
          <ul>
            <if @create_p@ eq 1 and @rels.rel_type_valid_p@ eq 1>
              <li><a href="@relations_add_url@">Add @rels.role_pretty_name@</a> </li>
            </if>
            <li>Relational segment: 
              <if @rels.segment_id@ nil>
                <em>#acs-subsite.none#</em> (<a href="../rel-segments/new?group_id=@group_id@&rel_type=@rels.rel_type@&return_url=@return_url_enc@">create segment</a>)
              </if>
              <else>
                <a href="../rel-segments/one?segment_id=@rels.segment_id@">@rels.segment_name@</a>
              </else>
            </li>
            <if @admin_p@ eq "1">
              <li><a href="rel-type-remove?group_rel_id=@rels.group_rel_id@">Remove this relationship type</a></li>
            </if>
          </ul>
        </li>
      </ul>

    </li>
  </multiple>
</else>

  <li> <a href="rel-type-add?group_id=@group_id@">#acs-subsite.Add_a_permissible_relationship_type#</a> </li>

</ul>
