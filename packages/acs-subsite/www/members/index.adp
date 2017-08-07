<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">@page_title;literal@</property>

<h3>@page_title@</h3>
<if @show_member_list_p;literal@ true>
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
  #acs-subsite.Mem_list_not_allowed#
</else>
