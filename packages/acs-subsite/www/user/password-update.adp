<master>
  <property name="title">#acs-subsite.Update_Password#</property>
  <property name="context">@context;noquote@</property>
  <property name="focus">@focus;noquote@</property>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<formtemplate id="update"></formtemplate>
