<master>
<property name="context">@context;noquote@</property>
<property name="title">All relations of type "@rel_type_pretty_name;noquote@"</property>
				   
<if @rels:rowcount@ eq 0>
 <ul>
   <li>(none)</li>
 </ul>
</if>
<else>
 <ol>
  <multiple name="rels">
    <li> <a href="../relations/one?rel_id=@rels.rel_id@">@rels.name@</a>
    </li>
  </multiple>
 </ol>
</else>
