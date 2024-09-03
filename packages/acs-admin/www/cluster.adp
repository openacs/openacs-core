<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>

<h1>@page_title@</h1>

<if @server_cluster_enabled_p;literal@ false>
  <p>Server Cluster is not enabled</p>
</if>
<else>
    <strong>Current node:</strong> @current_node@<br>
    <p>

    <listtemplate name="cluster_nodes" style="table-2third"></listtemplate>

</else>
