<div class="list-inline-filters">
<multiple name="filters">
    <p>
      <span class="list-inline-filter-label">@filters.filter_label@</span>
      <if @filters.filter_clear_url@ not nil>
        (<a href="@filters.filter_clear_url@" title="Clear the currently selected @filters.filter_label@">clear</a>)
      </if>
      <span class="list-inline-filter">[</span>

        <group column="filter_name">

          <if @filters.selected_p;literal@ true>
            <span class="list-inline-filter-selected">@filters.label@</span>
          </if>
          <else>
            <a href="@filters.url@" title="@filters.url_html_title@" class="list-inline-filter">@filters.label@</a>
          </else>

          <if @filters.count@ not nil and @filters.count@ ne "0">(@filters.count@)</if>

          <if @filters.add_url@ not nil>
            <a href="@filters.add_url@" class="list-inline-filter">+</a>
          </if>

          <if @filters.groupnum_last_p;literal@ false> | </if>
        </group>
      <span class="list-inline-filter">]</span>
    </p>
  </multiple>
</div>
