<master>
<property name="context">@context;noquote@</property>
<property name="title">Group Type "@group_type_pretty_name;noquote@"</property>
				   
<h4>Groups of this type</h4>

<ul>
  <if @groups:rowcount@ eq 0>
    <li>(none)</li>
  </if>
  <else>
    <multiple name="groups">
      <if @groups.rownum@ gt 25>
        <li> <a href="groups-display?group_type=@group_type_enc@">View all groups of this type</a> </li>
      </if>
      <else>
        <li> <a href="../groups/one?group_id=@groups.group_id@">@groups.group_name@</a> </li>
      </else>
    </multiple>
  </else>

  <p><li> <a href=../parties/new?party_type=@group_type_enc@&add_with_rel_type=composition_rel&return_url=@return_url_enc@>Add a group of this type</a>
</ul>

<h4>Attributes of this type of group</h4>

<ul>
  <multiple name="attributes">
    <if @attributes.ancestor_type@ eq @group_type_enc@>
      <li> <a href="../attributes/one?attribute_id=@attributes.attribute_id@&return_url=@return_url_enc@">@attributes.pretty_name@</a> 
    </if><else>
      <li> @attributes.pretty_name@ (via <a href=one?group_type=@attributes.ancestor_type@>@attributes.ancestor_pretty_name@</a>) 
    </else>
    </li>
  </multiple>

  <if @attributes:rowcount@ eq 0>
    <li>(none)</li>
  </if>

  <if @dynamic_p@ eq "t"> 
      <p><li> <a href="../attributes/add?object_type=@group_type_enc@&return_url=@return_url_enc@">Add an attribute</a>
  </if><else>
      <p><li> Attributes can only be added by programmers since this object type is not dynamically created
  </else>

</ul>


<h4>Default allowed relationship types</h4>

You can specify the default types of relationships that can be used
for groups of this type. Note that each group can later change its
allowed relationship types.

<ul>

  <if @allowed_relations:rowcount@ eq 0>
    <li>(none)</li>
  </if></else>
    <multiple name="allowed_relations">
      <li> <a href=../rel-types/one?rel_type=@allowed_relations.rel_type@>@allowed_relations.pretty_name@</a> (<a href=rel-type-remove?group_rel_type_id=@allowed_relations.group_rel_type_id@>remove</a>)
    </multiple>
  </else>

  <p><li> <a href="rel-type-add?group_type=@group_type_enc@">Add a permissible relationship type</a> </li>
</ul>



<h4>Administration</h4>

<ul>
  <if @dynamic_p@ eq "t"> 

      <li> Default join policy: @default_join_policy@
           (<a href=change-join-policy?group_type=@group_type_enc@>edit</a>)

      <li> <a href=delete?group_type=@group_type_enc@>Delete this group type</a>
  </if><else>
      <li> This group type can only be administered by programmers
  </else>

</ul>

