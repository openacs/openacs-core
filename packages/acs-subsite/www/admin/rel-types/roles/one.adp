<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">@role_props.pretty_name;literal@</property>

<p><b>Properties:</b>
<ul>
  <li> Role: @role@
  <li> Pretty name: @role_props.pretty_name@
  <li> Pretty plural: @role_props.pretty_plural@
  <li> <a href="edit?role=@role_enc@">Edit properties</a>
</ul>

<p><b>Relationship types that use this role:</b>

<ul>
  <if @rels:rowcount@ eq 0>
    <li> <em>(none)</em>
  </if><else>
  <multiple name="rels">
    <li> <a href="../one?rel_type=<%=[ad_urlencode $rels(rel_type)]%>">@rels.pretty_name@</a> (@rels.side@)
  </multiple>
  </else>
</ul>

<p><b>Administration</b>

<ul>
  <if @rels:rowcount@ eq 0>
    <li> <a href="delete?role=@role_enc@">Delete this role</a>
  </if><else>
    <li> You can only delete roles that are not in use.
  </else>
</ul>
