<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<if @asm_p@ eq 0>
	#acs-subsite.no_assessment#
</if>
<else>
<formtemplate id="get_assessment"></formtemplate>
</else>


