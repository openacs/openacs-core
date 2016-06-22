<%
    ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=iso-8859-1"	
%>
@header@
<h3>@title@</h3>
<a href="/pvt/home">Your Workspace</a> : Testing the timezone API
<hr>
<p>


<strong>Test 3</strong>
<p>
<em>Verify that data required to convert from local times for Europe/Paris into Universal Time
is loaded into the database.</em>
<p>
<table cellspacing="0" cellpadding="4" border="1">
<tr><th>Timezone</th><th>Start date</th><th>End date</th><th>UTC offset</th>
<multiple name=tz_results>
<tr><td>@tz_results.timezone@</td><td>@tz_results.local_start@</td>
<td>@tz_results.local_end@</td><td align="right">@tz_results.utc_offset@</td></tr>
</multiple>
</table>
<p>

<strong>Test 4</strong>
<p>
<em>Verify that the conversions between UTC and local time work correctly.</em>
<p>
<table cellspacing="0" cellpadding="4" border="1">
<tr bgcolor="#cc00ff"><th>Locale</th><th>Time</th><th>Test Passed?</th></tr>
<tr bgcolor="#cc00ff"><td>Oracle sysdate (should be UTC)</td><td>@system_time@</td><td>&nbsp;</td></tr>
<tr colspan="4"><td>&nbsp; </td></tr>
<tr bgcolor="#cccccc"><td>Local time in America/New_York</td><td>@NYC_time@</td><td>&nbsp; </td></tr>
<tr><td>UTC time (converted from New York time)</td><td>@NYC_utc_time@</td><td>@NYC_p@</tr>

<tr colspan="4"><td>&nbsp; </td></tr>
<tr bgcolor="#cccccc"><td>Local time in America/Los_Angeles</td><td>@LA_time@</td> <td>&nbsp; </td></tr>
<tr><td>UTC time (converted from Los Angeles time)</td><td>@LA_utc_time@</td><td>@LA_p@</td></tr>

<tr colspan="4"><td>&nbsp; </td></tr>

<tr bgcolor="#cccccc"><td>Local time in Europe/Paris</td><td>@paris_time@</td><td>&nbsp; </td> </tr>
<tr><td>UTC time (converted from Paris time)</td><td>@paris_utc_time@</td><td>@paris_p@</td></tr>

<tr colspan="4"><td>&nbsp; </td></tr>

<tr bgcolor="#cccccc"><td>Local time in Asia/Tokyo</td><td>@tokyo_time@</td><td>&nbsp; </td> </tr>
<tr><td>UTC time (converted from Tokyo time)</td><td>@tokyo_utc_time@</td><td>@tokyo_p@</td></tr>

</table>
<p>



@footer@




