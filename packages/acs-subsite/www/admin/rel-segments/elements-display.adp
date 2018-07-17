<h4><a href="@package_url@admin/rel-segments/one?segment_id=@segment_id@">@segment_name@</a></h4>

<ul>
  <if @elements:rowcount;literal@ eq 0>
    <li><em>(none)</em></li>
  </if>
  <else>
  
  <multiple name="elements">
    <li> @elements.name@
       <if @elements.direct_p;literal@ true>
         (direct relationship)
       </if><else>
         (through @elements.container_name@)
       </else> 
       <if @write_p;literal@ true> 
          (<a href="../relations/remove?rel_id=@elements.rel_id@">remove</a>)
       </if>
    </li>
  </multiple>

  </else>

</ul>
