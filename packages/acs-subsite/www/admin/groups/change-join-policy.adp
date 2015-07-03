<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">@group_name;literal@</property>

<blockquote>

<form method="post" action="change-join-policy-2">
<input type="hidden" name="group_id" value="@group_id@">
<input type="hidden" name="return_url" value="@QQreturn_url@">
<select name="join_policy">
<list name="possible_join_policies">
  <option value="@possible_join_policies:item@"
     <if @possible_join_policies:item@ eq @join_policy@>
         selected
     </if>
  >@possible_join_policies:item@
</list>
</select>

<input type="submit" value="Edit Join Policy">
</form>

</blockquote>