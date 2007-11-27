<master>
<property name="context">@context@</property>
<property name="title">@page_title@</property>

<if @show_member_list_p@ true>
  <table cellpadding="3" cellspacing="3">
    <tr>
      <td class="list-filter-pane" valign="top" style="width:200px">
        <listfilters name="members"></listfilters>
      </td>
      <td class="list-list-pane" valign="top">
        <listtemplate name="members"></listtemplate>
      </td>
    </tr>
  </table>
</if>
<else>
  <h4>@title@</h4>
  #acs-subsite.Mem_list_not_allowed#
</else>
