<master src="master">
  <property name="title">Localized Messages</property>
  <property name="context_bar">@context_bar;noquote@</property>

<p>You are editing locale: <strong>@locale_label@</strong> [ <tt>@current_locale@</tt> ]</p>

<if @pagination:rowcount@ ne "1">

<table cellspacing="2" cellpadding="2">
  <multiple name="pagination">
    <tr>
      <group column="group">    
        <if @pagination.selected@ eq "1">
          <td align="right" bgcolor="#ffffa">@pagination.text@
        </if>
        <else>
          <td align="right">
          <a href="@pagination.url@" title="@pagination.hint@">@pagination.text@</a>
        </else>
        </td>
      </group>
    </tr>
  </multiple>
</table>
</if>

<formtemplate id="batch_editor"></formtemplate>

<include src="lookups-include" package_key="@package_key;noquote@" message_key_list="@displayed_keys;noquote@">
