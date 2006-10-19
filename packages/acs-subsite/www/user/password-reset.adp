<master>
  <property name="title">#acs-subsite.Reset_Password#</property>
  <property name="context">@context;noquote@</property>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<formtemplate id="reset"></formtemplate>
