ad_page_contract {
    Test harness form for ad_page_contract

    @author Michael Yoon (michael@arsdigita.com)
    @cvs-id $Id$
} {}

doc_body_append "[ad_header "Test Harness for ad_page_contract"]

<body>

<h2>Test Harness</h2>

for <code>ad_page_contract</code>

<hr>

<form action=page-contract-test-2>

<blockquote>
<table>
<tr>
<th align=right>Non-HTML string:</th>
<td><input type=text name=str></td>
</tr>
<tr>
<th align=right>HTML string:</td>
<td><input type=text name=html_str></td>
</tr>
<tr>
<th align=right>Arbitrary HTML string:</td>
<td><input type=text name=any_html_str></td>
</tr>
<tr>
<th align=right>Not Empty:</td>
<td></td>
</tr>
<tr>
<th align=right>Integer:</td>
<td><input type=text name=int></td>
</tr>
<tr>
<th align=right>Negative Integer:</td>
<td><input type=text name=neg_int></td>
</tr>
<tr>
<th align=right>SQL Identifier:</td>
<td><input type=text name=sql_identifier></td>
</tr>
<tr>
<th align=right>Array key foo:</td>
<td><input type=text name=array.foo></td>
</tr>
<tr>
<th align=right>Array key bar.greble:</td>
<td><input type=text name=array.bar.greble></td>
</tr>
</table>
</blockquote>

<p>

<center><input type=submit value=\"Submit\"></center>

</form>

[ad_footer]
"

