<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>
  <property name="head">
  <style type="text/css">
  table.plain {background: #dddddd; border-spacing: 1px; border-collapse: separate;}
  table.plain tr {background: white;}
  table.plain td.high {text-align: left; padding: 2px; background: #ffffaa;}
  table.plain th, table.plain td {text-align: left; padding: 2px;}
  </style>
  </property>

<p>
  Show: 
  <multiple name="show_opts">
    <if @show_opts.rownum;literal@ gt 1> | </if>
    <if @show_opts.selected_p;literal@ true><strong>@show_opts.label@ (@show_opts.count@)</strong> </if>
    <else><a href="@show_opts.url@">@show_opts.label@ (@show_opts.count@)</a> </else>
  </multiple>
</p>

<if @total;literal@ eq 0>
  <em>No messages</em>
</if>
<else>
  <if @pagination:rowcount;literal@ ne "1">
      <table class="plain">
        <multiple name="pagination">
          <tr>
            <group column="group">    
              <if @pagination.selected;literal@ eq "1">
                <td class="high"><strong>@pagination.text@</strong>
              </if>
              <else>
                <td>
                <a href="@pagination.url@" title="@pagination.hint@">@pagination.text@</a>
              </else>
              </td>
            </group>
          </tr>
        </multiple>
      </table>
  </if>

  <!-- TODO: Remove 'style' when we've merged 4.6.4 back onto HEAD -->
  <formtemplate id="batch_editor"></formtemplate>

  <if @pagination:rowcount;literal@ ne "1">
      <table class="plain">
        <multiple name="pagination">
          <tr>
            <group column="group">    
              <if @pagination.selected;literal@ true>
                <td class="high"><strong>@pagination.text@</strong>
              </if>
              <else>
                <td>
                <a href="@pagination.url@" title="@pagination.hint@">@pagination.text@</a>
              </else>
              </td>
            </group>
          </tr>
        </multiple>
      </table>
  </if>
</else>
