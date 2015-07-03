<property name="focus">@focus;literal@</property>
<formtemplate id="user_info"></formtemplate>

<if @edit_mode_p@ true and @read_only_notice_p@ true>
    <p style="color: #ff0000;">#acs-subsite.Notice#</p> 
    <p>#acs-subsite.Elements_not_editable# </p>
</if>

