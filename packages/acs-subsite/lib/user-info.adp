<property name="focus">@focus;noquote@</property>

<formtemplate id="user_info"></formtemplate>

<if @edit_mode_p@ true and @read_only_notice_p@ true>
  <p> <font color="red">Notice:</font> Certain elements are not editable, because they are managed by @authority_name@. </p>
</if>
