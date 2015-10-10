<master>
<property name="&doc">doc</property>
<property name="context">@context;literal@</property>

<h1>@doc.title@</h1>

<p>#acs-subsite.Currently_the_system_is#:</p>

<ul>

  <if @group_types:rowcount@ eq 0>
    <li>#acs-subsite.none#</li>
  </if>
  <else>
  
  <multiple name="group_types">
    <li> @group_types.indent;noquote@<a href="one?group_type=@group_types.group_type@">@group_types.pretty_plural@</a> (#acs-subsite.number_of_groups_defined#: @group_types.number_groups@)
    </li>
  </multiple>

  </else>

</ul>

  <p><a href="new" class="button">#acs-subsite.Define_a_new_group_type#</a></p>

