<master>
<property name="context">@context;noquote@</property>
<property name="title">Group type administration</property>

Currently, the system is able to handle the following types of groups: 

<ul>

  <if @group_types:rowcount@ eq 0>
    <li>(none)</li>
  </if>
  <else>
  
  <multiple name="group_types">
    <li> @group_types.indent;noquote@<a href="one?group_type=@group_types.group_type@">@group_types.pretty_plural@</a> (number of groups defined: @group_types.number_groups@)
    </li>
  </multiple>

  </else>

  <p>
  <li><a href="new">Define a new group type</a>
</ul>

