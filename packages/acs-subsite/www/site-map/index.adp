<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>	
<property name="javascript">@javascript;noquote@</property>
<script language=javascript>

<!--

function check_checkbox () {
	window.document.nodes.node_id.checked='true'


}

// -->

</script>

<small>
	

<listtemplate name="nodes"></listtemplate>

<if @site_wide_admin_p@>
	<br>
	<a href="/admin/site-map/site-map">Edit this Site Map</a>
</if>
