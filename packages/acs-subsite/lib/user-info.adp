<property name="focus">@focus;noquote@</property>
<formtemplate id="user_info"></formtemplate>

<if @edit_mode_p@ true and @read_only_notice_p@ true>
  <p> <font color="red">#acs-subsite.Notice#</font> #acs-subsite.Elements_not_editable# </p>
</if>

<h2>#acs-subsite.You_are_in_the_follow#</h2>
<ul>
<multiple name="groups">
  <li>@groups.group_name@</li>
</multiple>
</ul>

