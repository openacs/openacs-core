  <master>
    <property name="doc(title)">#acs-subsite.Permissions#</property>
    <property name="context">@context;literal@</property>

    <if @objects:rowcount;literal@ gt 0> 
      #acs-subsite.You_have_admin_rights_on#
      <ul>
        <multiple name="objects">

          <li> <if @objects.object_id@ eq @root@ and @objects.context_id@ not nil> <a href="./?root=@objects.context_id@">#acs-subsite.UP#</a></if>
          <if @objects.object_id@ ne @root@><a href="./?root=@objects.object_id@">+</a></if>
	  <strong>@objects.name@</strong>
	  @objects.object_type@
	  <if @objects.object_id@ not nil><a href="@objects.url;noi18n@">@objects.url;noi18n@</a>:
	  </if>
	  <a href="one?object_id=@objects.object_id@">#acs-subsite.permissions#</a></li>

        </multiple>
      </ul>
    </if>
    <else>
      <em>#acs-subsite.You_do_not_have_admin_on#<em>
    </else>
    <form method="get" action="one">
      <div>
      #acs-subsite.Select_an_Object_by_Id#
      <input name="object_id" type="text"> <input value="Continue" type="submit">
      </div>
    </form>
<if @admin_p;literal@ true><p>
#acs-subsite.You_can_also_browse_from# <a href="./?root=@default_context@">#acs-subsite.default_context#</a>
#acs-subsite.or_the# <a href="./?root=@security_context_root@">#acs-subsite.Security_context_root#</a>#acs-subsite._or# <a href="./?root=@subsite@">#acs-subsite.this_subsite#</a>.
</p></if>
