<h4><a href="@package_url@admin/rel-segments/one?segment_id=@segment_id@">@segment_name@</a></h4>

<ul>
  <if @elements:rowcount@ eq 0>
    <li><em>(none)</em></li>
  </if>
  <else>
  
  <multiple name="elements">
    <li> @elements.name@
       <if @elements.direct_p@ eq 1>
         (direct relationship)
       </if><else>
         (through @elements.container_name@)
       </else> 
       <if @write_p@ eq "1"> 
          (<a href="../relations/remove?rel_id=@elements.rel_id@">remove</a>)
       </if>
    </li>
  </multiple>

  </else>

</ul>
