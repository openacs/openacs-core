  <master>
    <property name="title">Permissions</property>
    <property name="context">@context@</property>

    <if @objects:rowcount@ gt 0> 
      You have admin rights on the following objects:
      <ul>
        <multiple name="objects">

          <li> <if @objects.object_id@ eq @root@ and @objects.context_id@ not nil> <a href="./?root=@objects.context_id@">UP</a></if>
          <if @objects.object_id@ ne @root@><a href="./?root=@objects.object_id@">+</a></if> <strong>@objects.name@</strong> @objects.object_type@ <a href="one?object_id=@objects.object_id@">permissions</a></li>

        </multiple>
      </ul>
    </if>
    <else>
      <em>You do not have admin rights on object @root@ or any of it's children<em>
    </else>

    <form method="get" action="one">
      Select an Object by Id:
      <input name="object_id" type="text"> <input value="Continue" type="submit">
    </form>

<if @admin_p@><p>
You can also browse from the <a href="./?root=@default_context@">default context</a>
or the <a href="./?root=@security_context_root@">Security context root</a>, or <a href="./?root=@subsite@">this subsite</a>.
</p></if>