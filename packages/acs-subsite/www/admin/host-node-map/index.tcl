ad_page_contract {
    @author Mark Dettinger (mdettinger@arsdigita.com)
    @creation-date 2000-10-24
    @cvs-id $Id$
} {
}

set table ""
append table "<tr>
<td>[ns_config ns/server/[ns_info server]/module/nssock Hostname]</td>
<td>[db_string root_id  "select site_node.node_id('/') from dual"]</td>
<td>/</td>
<td>&nbsp;</td>
</tr>"
db_foreach host_node_pair {
    select host, node_id, site_node.url(node_id) as url 
    from host_node_map
} {
    append table "<tr>
    <td><a href=\"http://$host\">$host</a></td>
    <td>$node_id</td>
    <td>$url</td>
    <td><a href=delete?host=$host&node_id=$node_id>delete</a></td>
    </tr>"
} 

set nodes ""
set root_id [ad_conn node_id]
db_foreach node_list {
    select name, node_id
    from site_nodes
    order by name
} {
    append nodes "<input type=radio name=root value=$node_id> /$name<br>"
}


doc_body_append "
[ad_header "Host-Node Map"]
<h2>Host-Node Map</h2>
[ad_context_bar "Host-Node Map"]
<hr>
<h3>Registered hostname/URL pairs</h3>
<table border>
<tr>
  <th>Hostname</th>
  <th>Root Node</th>
  <th>Root URL</th>
  <th>Action</th>
</tr>
$table
</table>
<h3>Add another hostname/URL pair</h3>
<form method=get action=add>
<table border>
<tr>
  <th>Hostname</th>
  <th>Root URL</th>
</tr>
<tr>
  <td valign=top><input type=text name=host value=myname.com></td>
  <td>$nodes</td>
</tr>
</table>
<input type=submit value=Add>
</form>
[ad_footer]
"






