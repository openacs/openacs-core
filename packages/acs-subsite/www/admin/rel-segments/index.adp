<master>
<property name="context">@context;literal@</property>
<property name="&doc">doc</property>

<h1>@doc.title@</h1>

<p>#acs-subsite.Currently_the_system_is_able_to_handle_the_following_relational_segments#</p>

<ul>

  <if @seg:rowcount@ eq 0>
    <li>#acs-subsite.none#</li>
  </if>
  <else>
  
  <multiple name="seg">
    <li> <a href="one?segment_id=@seg.segment_id@">@seg.segment_name@</a> (<a href="../rel-types/one?rel_type=@seg.rel_type@">@seg.rel_type_pretty_name@</a> to <a href="../groups/one?group_id=@seg.group_id@">@seg.group_name@</a>)
    </li>
  </multiple>

  </else>

</ul>

<p>#acs-subsite.Note_Relational_segments_are_created_from_the_groups_administration_pages#</p>
