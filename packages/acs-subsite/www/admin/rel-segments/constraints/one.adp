<master>
<property name="context">@context;noquote@</property>
<property name="title">@props.constraint_name;noquote@</property>

All elements in side @props.rel_side@ of the segment 
  <a href=../one?segment_id=@props.segment_id@>@props.segment_name@</a> 
must be in the segment 
  <a href=../one?segment_id=@props.req_segment_id@>@props.req_segment_name@</a>

<p>

In other words, before creating a @rel.rel_type_pretty_name@ to the group @props.group_name@, 
the @rel.role_pretty_name@ must be a @req_rel.role_pretty_name@ of the group @props.req_group_name@.


<if @admin_p@ eq 1>
  <h4>Administration</h4>
  <ul>
    <li> <a href="delete?constraint_id=@props.constraint_id@">Delete this constraint</a>
  </ul>
</if>
