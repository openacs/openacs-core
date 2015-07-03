<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>	
<property name="javascript">@javascript;literal@</property>
<script type="text/javascript">

<!--

function check_checkbox () {
	window.document.nodes.node_id.checked='true'


}

// -->

</script>

<listtemplate name="nodes"></listtemplate>

<if @site_wide_admin_p@>
	<p><a href="/admin/site-map/site-map" class="button">Edit Site Map</a></p>
</if>

