<master>
<property name="context">@context;literal@</property>
<property name="&doc">doc</property>
				   
<h1>@doc.title@</h1>

<ul>
<li>Group: @type_info.pretty_name@
<li>Supertype: <a href="one?group_type=@type_info.supertype@">@type_info.supertype@</a>
</ul>

<h2>#acs-subsite.Groups_of_this_type#</h2>

<blockquote>
  <if @groups:rowcount@ eq 0>
    <p>(#acs-subsite.none#)</p>
  </if>
  <else>
  <ul>
  <multiple name="groups">
      <if @groups.rownum@ gt 25>
        <li> <a href="groups-display?group_type=@group_type_enc@">#acs-subsite.View_all_groups_of_this_type#</a> </li>
      </if>
      <else>
        <li> <a href="../groups/one?group_id=@groups.group_id;literal@">@groups.group_name@</a> </li>
      </else>
  </multiple>
  </ul>
  </else>
  <a href="@add_group_url@" class="button">#acs-subsite.Add_a_group_of_this_type#</a>
</blockquote>

<h2>#acs-subsite.Attributes_of_this_type_of_group#</h2>

<ul>
  <multiple name="attributes">
    <if @attributes.ancestor_type@ eq @group_type_enc@>
      <li><a href="@attributes.one_attribute_url@">@attributes.pretty_name@</a></li>
    </if>
    <else>
      <li>@attributes.pretty_name@ (via <a href="one?group_type=@attributes.ancestor_type@">@attributes.ancestor_pretty_name@</a>)</li>
    </else>
  </multiple>

  <if @attributes:rowcount@ eq 0>
    <li>#acs-subsite.none#</li>
  </if>
</ul>
<ul>
  <if @dynamic_p;literal@ true> 
      <li><a href="@add_attribute_url@" class="button">#acs-subsite.Add_an_attribute#</a></li>
  </if>
  <else>
      <li>#acs-subsite.Attributes_can_only_be_added_by_programmers#</li>
  </else>
</ul>


<h2>#acs-subsite.Default_allowed_relationship_types#</h2>

<p>#acs-subsite.You_can_specify_the_default_types_of#</p>

<ul>

  <if @allowed_relations:rowcount@ eq 0>
    <li>#acs-subsite.none#</li>
  </if>
  <else>
    <multiple name="allowed_relations">
      <li><a href="../rel-types/one?rel_type=@allowed_relations.rel_type@">@allowed_relations.pretty_name@</a> (<a href="rel-type-remove?group_rel_type_id=@allowed_relations.group_rel_type_id@">#acs-subsite.remove#</a>)</li>
    </multiple>
  </else>
</ul>
<ul>
  <li><a href="rel-type-add?group_type=@group_type_enc@" class="button">#acs-subsite.Add_a_permissible_relationship_type#</a></li>
</ul>


<h2>#acs-subsite.Administration#</h2>

<ul>
  <if @dynamic_p;literal@ true> 

      <li>#acs-subsite.Default_join_policy#: @default_join_policy@
           (<a href="change-join-policy?group_type=@group_type_enc@">#acs-subsite.edit#</a>)
        </li>
      <li> <a href="delete?group_type=@group_type_enc@" class="button">#acs-subsite.Delete_this_group_type#</a>
      </li>
  </if>
  <else>
      <li>#acs-subsite.This_group_type_can_only_be_administered_by_programmers#</li>
  </else>

</ul>
