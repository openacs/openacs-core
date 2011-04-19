<master>
<property name="context">@context;noquote@</property>
<property name="doc(title)">#acs-subsite.Relationship_types_administration#</property>

<h1>#acs-subsite.Relationship_types_administration#</h1>

<p>#acs-subsite.Currently_the_system_is_able_to_handle_the_following_types_of_relationships#</p>

<ul>

  <if @rel_types:rowcount@ eq 0>
    <li><em>#acs-subsite.none#</em></li>
  </if>
  <else>
  
  <multiple name="rel_types">
    <li>@rel_types.indent;noquote@<a href="one?rel_type=@rel_types.rel_type@">@rel_types.pretty_name@</a> (#acs-subsite.number_of_relationships_defined#: @rel_types.number_relationships@)
    </li>
  </multiple>

  </else>
</ul>

<ul>
  <li><a href="new">#acs-subsite.Define_a_new_relationship_type#</a></li>
  <li><a href="roles">#acs-subsite.View_all_roles#</a></li>
</ul>


