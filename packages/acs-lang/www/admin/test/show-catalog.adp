<%
    ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=utf-8"	
%>


<master>
Message Catalog
<table border="1">
<tr>
<th></th>
<th>Lang</th>
<th>Message</th>
</tr>
<multiple name=catalog>
<tr><th bgcolor="#cccccc" colspan="3" align="left">@catalog.key@</td></tr>
<group column=key>
<tr>
<td width=20></td>
<td> @catalog.locale@</td>
<td> @catalog.message@</td>
</tr>
</group>
</multiple>
</table>
