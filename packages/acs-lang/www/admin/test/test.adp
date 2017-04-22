<%
    ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=iso-8859-1"	
%>
@header@
<h3>@title@</h3>
<a href="/pvt/home">Your Workspace</a> : Testing the language and localization API
<hr>
<p>
<strong>Test 1</strong>
<p>
<em>Verify that the message catalog loader ran
successfully at server startup.</em>
<p>
<table cellspacing="0" cellpadding="4" border="1">
<tr><th>Word to lookup</th><th>Language</th><th>Results of catalog lookup</th></tr>
<tr><td>English</td><td>English</td><td>@english@</td></tr>
<tr><td>French</td><td>French</td><td>@french@</td></tr>
<tr><td>Spanish</td><td>Spanish</td><td>@spanish@</td></tr>
<tr><td>German</td><td>German</td><td>@german@</td></tr>
</table>
<p>

<strong>Test 2</strong>
<p>
<em>Verify that the &lt;trn&gt; ADP tag works when the user's preferred
language is set to 
<a href="locale-set?locale=en">English</a>,
<a href="locale-set?locale=fr">French</a>,
<a href="locale-set?locale=es">Spanish</a>,
or <a href="locale-set?locale=de">German</a></em>.
<p>
<table cellspacing="0" cellpadding="4" border="1">
<tr><th>Word to lookup</th><th>Result when user's preferred language is @language@</tr>
<tr><td>English</td><td>@trn_english@</td></tr>
<tr><td>French</td><td>@trn_french@</tr>
<tr><td>Spanish</td><td>@trn_spanish@</td></tr>
<tr><td>German</td><td>@trn_german@</td></td></tr>
</table>
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
<tr><td>Oracle sysdate (should be UTC)</td><td>@system_time@</td></tr>
<tr><td>Local time in Europe/Paris</td><td>@paris_time@</td></tr>
<tr><td>UTC time (converted from Paris time)</td><td>@local_time@</tr>
<tr><td>Local time in Tokyo, Japan</td><td>@tokyo_time@</td></tr>
<tr><td>UTC time (converted from Tokyo time)</td><td>@tokyo_utc_time@</tr>
</table>
<p>

<strong>Test 5</strong>
<p>
<em>Verify the results of localization routines.</em>
<p>
<table cellspacing="0" cellpadding="4" border="1">
            <tr><th>Routine</th><th>en_US locale</th>
                <th>en_FR locale</th></tr>
            <tr><td>Displaying a number</td>
                <td>@us_number@</td>
                <td>@fr_number@</td></tr>
            <tr><td>Parsing a number</td>
                <td>@us_parse@</td>
                <td>@fr_parse@</td></tr>
            <tr><td rowspan="2" valign="top">Displaying a monetary amount</td>
                <td>@us_currency@</td>
                <td>@fr_currency@</td></tr>
            <tr><td>@us_label@</td>
                <td>@fr_label@</td></tr>
            <tr><td>Displaying a date</td>
                <td>@us_time@</td>
                <td>@fr_time@</td></tr>
            </table>
<p>

@footer@




