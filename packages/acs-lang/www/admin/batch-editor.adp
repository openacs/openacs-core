<master src="master">
  <property name="title">Localized Messages</property>
  <property name="context_bar">@context_bar;noquote@</property>

<p>You are editing locale: <strong>@locale_label@</strong> [ <tt>@current_locale@</tt> ]</p>

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

