<%
  set first_p 1
  %>
  <multiple name="filters">
    <group column="filter_name">
      <if @filters.selected_p@ and @filters.filter_name@ ne "groupby">
	<if @filters.rownum@ eq 1>, </if><else><b>Filtered by:</b> <% set first_p 0 %></else>@filters.filter_label@: @filters.label@ <if @filters.filter_clear_url@ not nil>
           <super>[<a href="@filters.filter_clear_url@" title="Clear the currently selected @filters.filter_label@">x</a>]</super>
         </if>
</if>
    </group>
  </multiple>