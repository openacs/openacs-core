<master>
<property name="context">@context;noquote@</property>
<property name="title">Relational Segment administration</property>

Currently, the system is able to handle the following relational segments:

<ul>

  <if @seg:rowcount@ eq 0>
    <li>(none)</li>
  </if>
  <else>
  
  <multiple name="seg">
    <li> <a href="one?segment_id=@seg.segment_id@">@seg.segment_name@</a> (<a href=../rel-types/one?rel_type=@seg.rel_type@>@seg.rel_type_pretty_name@</a> to <a href=../groups/one?group_id=@seg.group_id@>@seg.group_name@</a>)
    </li>
  </multiple>

  </else>

</ul>

Note: Relational segments are created from the <a href=../groups/>groups administration pages</a>
