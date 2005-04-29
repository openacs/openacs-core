<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<if @asm_p@ eq 0>
	#acs-subsite.no_assessment#
</if>
<else>
<a href="@new_url@asm-admin/assessment-form?permission_p=1" class="button">#acs-subsite.create_asm#</a>
<br>
<br>
<formtemplate id="get_assessment">
</formtemplate>
</else>


