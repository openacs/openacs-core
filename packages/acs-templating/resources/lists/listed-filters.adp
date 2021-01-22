<% set selected_rownum 1 %>
<multiple name="filters">
  <group column="filter_name">
    <if @filters.selected_p@ and @filters.filter_name@ ne "groupby">
      <if @selected_rownum@ eq 1><strong>Filtered by:</strong> </if>
      <elseif @selected_rownum@ gt 1>, </elseif>
      @filters.filter_label@: @filters.label@
      <if @filters.filter_clear_url@ not nil>
        <super>[<a href="@filters.filter_clear_url@" title="Clear the currently selected @filters.filter_label@">x</a>]</super>
      </if>
      <% incr selected_rownum %>
    </if>
  </group>
</multiple>
