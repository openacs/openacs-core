<master>
<property name="context">@context@</property>
<property name="title">@page_title@</property>

<if @show_members_list_p@>
  <table cellpadding="3" cellspacing="3">
    <tr>
      <td class="list-filter-pane" valign="top" width="200">
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
  Sorry, but you are not allowed to view the members list.
</else>
