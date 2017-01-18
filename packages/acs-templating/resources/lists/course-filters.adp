<multiple name="filters">
  <if @filters.filter_name@ ne "groupby" and @filters.filter_name@ ne
  "orderby">
  <p style="margin-top: 0px; margin-bottom: 12px;">
    <table border="0" cellspacing="0" cellpadding="2" width="100%">
      <tr>
        <td colspan="3" class="list-filter-header">
         @filters.filter_label@
         <if @filters.filter_clear_url@ not nil>
           (<a href="@filters.filter_clear_url@" title="Clear the currently selected @filters.filter_label@">clear</a>)
         </if>
        </td>
      </tr>
      <group column="filter_name">
        <if @filters.selected_p;literal@ true>
          <tr class="list-filter-selected">
        </if>
        <else>
          <tr>
        </else>
          <td class="list-filter">
            <if @filters.selected_p;literal@ true><span class="list-filter-selected">@filters.label@</span></if>
            <else><a href="@filters.url@" title="@filters.url_html_title@">@filters.label@</a></else>
          </td>
          <td align="right" class="list-filter">
            <if @filters.count@ ne "0">@filters.count@</if>
          </td>
          <td align="right" class="list-filter">
            <if @filters.add_url@ not nil>
              <a href="@filters.add_url@">+</a>
            </if>
          </td>
        </tr>
      </group>
    </table>
  </p>
  </if>
</multiple>
