<master>
<property name="context">@context@</property>
<property name="title">@page_title@</property>

<if @show_members_list_p@>
<listtemplate name="members"></listtemplate>
</if>
<else>
<h4>@title@</h4>
Sorry, but you are not allowed to view the members list.
</else>
