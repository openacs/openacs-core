<if @results_paginator:rowcount@ gt 0>
  <div id="results-pages" class="@paginator_class@">
    <ul class="compact list-paginator">
      <if @url_previous_group@ nil>
        <li>&lt;&lt;</li>
      </if>
      <else>
        <li><a href="@url_previous_group@">&lt;&lt;</a></li>
      </else>
      <if @url_previous@ nil>
        <li>&lt;</li>
      </if>
      <else>
        <li><a href="@url_previous@">&lt;</a></li>
      </else>
      <multiple name="results_paginator">
        <if @results_paginator.current_p;literal@ true>
          <li class="current">@results_paginator.item@</li>
        </if>
        <else>
          <li><a href="@results_paginator.link@">@results_paginator.item@</a></li>
        </else>
      </multiple>
      <if @url_next@ nil>
       <li>&gt;</li>
      </if>
      <else>
        <li><a href="@url_next@">&gt;</a></li>
      </else>
      <if @url_next_group@ nil>
        <li>&gt;&gt;</li>
      </if>
      <else>
        <li><a href="@url_next_group@">&gt;&gt;</a></li>
      </else>
    </ul>
  </div>
</if>
