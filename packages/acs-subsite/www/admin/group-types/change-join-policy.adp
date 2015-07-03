<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">@group_type_pretty_name;literal@</property>

<blockquote>

<form method="post" action="change-join-policy-2">
<input type="hidden" name="group_type" value="@QQgroup_type@">
<input type="hidden" name="return_url" value="@QQreturn_url@">
<select name="default_join_policy">
<list name="possible_join_policies">
  <option value="@possible_join_policies:item@"
     <if @possible_join_policies:item@ eq @default_join_policy@>
         selected
     </if>
  >@possible_join_policies:item@
</list>
</select>

<input type="submit" value="Edit Default Join Policy">
</form>

</blockquote>