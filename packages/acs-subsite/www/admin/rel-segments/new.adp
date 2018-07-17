<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Create relational segment</property>
<property name="focus">segment_new.segment_name</property>

<if @rel_types:rowcount;literal@ eq 0>

  <strong>There are no relationship types for which to create segments</strong>

</if><else>

You are creating a segment for 
<if @subsite_group_id@ eq @group_id@>
    <a href="../groups/index?view_by=rel_type">@group_name@</a>
</if>
<else>
    <a href="../groups/one?group_id=@group_id@">@group_name@</a>
</else>

<p>

<form name="segment_new" method="get" action="new-3">
@export_vars;noquote@

Segment Name:
  <input type="text" name="segment_name" maxlength="230">

<p> Relationship type for which to create the segment:
  <select name="rel_type">
    <multiple name="rel_types">
      <option value="@rel_types.rel_type@"> @rel_types.indent@@rel_types.pretty_name@
    </multiple>
  </select>
  </if>
</else>

<p>

<center><input type="submit" value="Create"></center>

</form>


