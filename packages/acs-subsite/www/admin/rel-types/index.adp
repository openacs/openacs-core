<master>
<property name="context">@context;noquote@</property>
<property name="title">Relationship administration</property>

Currently, the system is able to handle the following types of relationships: 

<ul>

  <if @rel_types:rowcount@ eq 0>
    <li><em>(none)</em></li>
  </if>
  <else>
  
  <multiple name="rel_types">
    <li> @rel_types.indent;noquote@<a href="one?rel_type=@rel_types.rel_type@">@rel_types.pretty_name@</a> (number of relationships defined: @rel_types.number_relationships@)
    </li>
  </multiple>

  </else>

  <p>
  <li><a href="new">Define a new relationship type</a>
  <li><a href="roles">View all roles</a>
</ul>


