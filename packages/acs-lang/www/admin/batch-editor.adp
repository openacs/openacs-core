<master>
  <property name="doc(title)">@page_title@</property>
  <property name="context">@context;noquote@</property>
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
    <if @show_opts.rownum@ gt 1> | </if>
    <if @show_opts.selected_p@><b>@show_opts.label@ (@show_opts.count@)</b> </if>
    <else><a href="@show_opts.url@">@show_opts.label@ (@show_opts.count@)</a> </else>
  </multiple>
</p>

<if @total@ eq 0>
  <i>No messages</i>
</if>
<else>
  <if @pagination:rowcount@ ne "1">
      <table class="plain">
        <multiple name="pagination">
          <tr>
            <group column="group">    
              <if @pagination.selected@ eq "1">
                <td class="high"><b>@pagination.text@</b>
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

  <if @pagination:rowcount@ ne "1">
      <table class="plain">
        <multiple name="pagination">
          <tr>
            <group column="group">    
              <if @pagination.selected@ eq "1">
                <td class="high"><b>@pagination.text@</b>
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
