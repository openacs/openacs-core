<master>
  <property name="title">@page_title@</property>
  <property name="context">@context;noquote@</property>

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
    <p>
      <table cellspacing="1" cellpadding="2" bgcolor="#dddddd">
        <multiple name="pagination">
          <tr bgcolor="white">
            <group column="group">    
              <if @pagination.selected@ eq "1">
                <td align="left" bgcolor="#ffffa"><b>@pagination.text@</b>
              </if>
              <else>
                <td align="left">
                <a href="@pagination.url@" title="@pagination.hint@">@pagination.text@</a>
              </else>
              </td>
            </group>
          </tr>
        </multiple>
      </table>
    </p>
  </if>

  <!-- TODO: Remove 'style' when we've merged 4.6.4 back onto HEAD -->
  <formtemplate id="batch_editor"></formtemplate>

  <if @pagination:rowcount@ ne "1">
    <p>
      <table cellspacing="1" cellpadding="2" bgcolor="#dddddd">
        <multiple name="pagination">
          <tr bgcolor="white">
            <group column="group">    
              <if @pagination.selected@ eq "1">
                <td align="left" bgcolor="#ffffa"><b>@pagination.text@</b>
              </if>
              <else>
                <td align="left">
                <a href="@pagination.url@" title="@pagination.hint@">@pagination.text@</a>
              </else>
              </td>
            </group>
          </tr>
        </multiple>
      </table>
    </p>
  </if>
</else>
