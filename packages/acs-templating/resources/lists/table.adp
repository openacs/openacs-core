<table class="@list_properties.class@" cellpadding="3" cellspacing="1"@list_properties.table_attributes;noquote@>

<if @list_properties.bulk_actions@ not nil>
  <if @list_properties.bulk_action_method@ not nil>
  <form name="@list_properties.name@" method="@list_properties.bulk_action_method@">  
  </if>
  <else>
  <form name="@list_properties.name@" method="GET">
  </else>
  @list_properties.bulk_action_export_chunk;noquote@
</if>

<if @list_properties.page_size@ not nil>
  <noparse>
    <if \@paginator.page_count@ gt 1>
      <tr width="100%" class="list-paginator">
        <td colspan="@elements:rowcount@" align="center">
          <if \@paginator.group_count@ gt 1>
            <if \@paginator.previous_group_url@ not nil>
              <a href="\@paginator.previous_group_url@" title="\@paginator.previous_group_context@">&lt;&lt;</a>
            </if>
            <else>
              &lt;&lt;
            </else>
          </if>
          <if \@paginator.previous_page_url@ not nil>
            &nbsp;<a href="\@paginator.previous_page_url@" title="\@paginator.previous_page_context@">&lt;</a>&nbsp;
          </if>
          <else>
            &nbsp;&lt;&nbsp;
          </else>

          <multiple name="paginator_pages">
            <if \@paginator.current_page@ ne \@paginator_pages.page@>
              <if \@paginator_pages.page@ lt 10>&nbsp;&nbsp;</if><a 
              href="\@paginator_pages.url@" title="\@paginator_pages.context@">\@paginator_pages.page@</a>
            </if>
            <else>
              <if \@paginator_pages.page@ lt 10>&nbsp;&nbsp;</if><b>\@paginator_pages.page@</b>
            </else>
          </multiple>

          <if \@paginator.next_page_url@ not nil>
            &nbsp;<a href="\@paginator.next_page_url@" title="\@paginator.next_page_context@">&gt;</a>&nbsp;
          </if>
          <else>
            &nbsp;&gt;&nbsp;
          </else>
          <if \@paginator.group_count@ gt 1>
            <if \@paginator.next_group_url@ not nil>
              <a href="\@paginator.next_group_url@" title="\@paginator.next_group_context@">&gt;&gt;</a>
            </if>
            <else>
              &gt;&gt;
            </else>
          </if>
        </td>
      </tr>
    </if>
  </noparse>
</if>

<if @actions:rowcount@ gt 0>
  <tr class="list-button-bar">
    <td colspan="@elements:rowcount@" class="list-button-bar">
      <multiple name="actions">
        <a href="@actions.url@" title="@actions.title@" class="button">@actions.label@</a>
      </multiple>
    </td>
  </tr>
</if>


  <multiple name="elements">
    <tr class="list-header">
      <group column="subrownum">
        <th class="@elements.class@"@elements.cell_attributes;noquote@>
          <if @elements.orderby_url@ not nil>
            <if @elements.ordering_p@ true>
              <a href="@elements.orderby_url@" title="@elements.orderby_html_title@">@elements.label;noquote@</a>
              <a href="@elements.orderby_url@" title="@elements.orderby_html_title@"><if @elements.orderby_direction@ eq "desc"><img src="/resources/acs-templating/sort-descending.png" alt="" /></if><else><img src="/resources/acs-templating/sort-ascending.png" alt="" /></else></a>
            </if>
            <else>
              <a href="@elements.orderby_url@" title="@elements.orderby_html_title@">@elements.label;noquote@ <img src="/resources/acs-templating/sort-neither.png" alt="" /></a>
            </else>
          </if>
          <else>
            @elements.label;noquote@
          </else>
        </th>
      </group>
    </tr>
  </multiple>

<noparse>
  <if \@@list_properties.multirow@:rowcount@ eq 0>
    <tr class="list-odd last">
      <td colspan="@elements:rowcount@">
        @list_properties.no_data@
      </td>
    </tr>
  </if>
  <else>
    <multiple name="@list_properties.multirow@">
</noparse>
      
  <if @list_properties.groupby@ not nil>

      <tr class="list-subheader">
        <td colspan="@elements:rowcount@">
          @list_properties.groupby_label@: <listelement name="@list_properties.groupby@">
        </td>
      </tr>

      <noparse>
        <group column="@list_properties.groupby@">
      </noparse>
  </if>

        <multiple name="elements">
  <noparse>
          <if \@@list_properties.multirow@.rownum@ lt \@@list_properties.multirow@:rowcount@>
            <if \@@list_properties.multirow@.rownum@ odd>
              <tr class="list-odd">
            </if>
            <else>
              <tr class="list-even">
            </else>
          </if>
          <else>
            <if \@@list_properties.multirow@.rownum@ odd>
              <tr class="list-odd last">
            </if>
            <else>
              <tr class="list-even last">
            </else>
          </else>
  </noparse>

            <group column="subrownum">
              <td class="@elements.class@"@elements.cell_attributes;noquote@>
                <listelement name="@elements.name@">
              </td>
            </group>
          </tr>
        </multiple>

  <if @list_properties.groupby@ not nil>
          <noparse><if \@@list_properties.multirow@.groupnum_last_p@ true></noparse>
            <multiple name="elements">
              <tr class="list-subheader">
                <group column="subrownum">
                  <td class="@elements.class@"@elements.cell_attributes;noquote@>
                    <if @elements.aggregate_group_label@ not nil>
                      @elements.aggregate_group_label@
                    </if>
                    <if @elements.aggregate@ not nil>
                      \@@list_properties.multirow@.@elements.aggregate_group_col@@
                    </if>
                  </td>
                </group>
              </tr>
            </multiple>
          <noparse></if></noparse>

       <noparse>
        </group>
      </noparse>
  </if>

  <if @list_properties.aggregates_p@ true>
    <noparse><if \@@list_properties.multirow@.rownum@ eq \@@list_properties.multirow@:rowcount@></noparse>
      <multiple name="elements">
        <tr class="list-subheader last">
          <group column="subrownum">
            <td class="@elements.class@"@elements.cell_attributes;noquote@>
              <if @elements.aggregate_label@ not nil>
                @elements.aggregate_label@
              </if>
              <if @elements.aggregate@ not nil>
                \@@list_properties.multirow@.@elements.aggregate_col@@
              </if>
            </td>
          </group>
        </tr>
      </multiple>
    <noparse></if></noparse>
  </if>

  <noparse>
      </multiple>
    </else>
  </noparse>


<noparse><if \@@list_properties.multirow@:rowcount@ gt 0></noparse>
  <if @bulk_actions:rowcount@ gt 0>
    <tr class="list-button-bar">
      <td colspan="@elements:rowcount@" class="list-button-bar">
        <multiple name="bulk_actions">
          <a href="#" title="@bulk_actions.title@" class="button"
          onclick="acs_ListBulkActionClick('@list_properties.name@', '@bulk_actions.url@'); return false;">@bulk_actions.label@</a>
        </multiple>
      </td>
    </tr>
  </if>
<noparse></if></noparse>


<if @list_properties.bulk_actions@ not nil>
  </form>
</if>

</table>
