proc ::foo {} {
    return "foo bar baz greble"
}
ad_page_contract {
    Test harness results for ad_page_contract

    @author Michael Yoon (michael@arsdigita.com)
    @cvs-id $Id$
} {
    str:nohtml
    html_str:html
    any_html_str:allhtml
    int:integer,trim
    neg_int:integer
    sql_identifier:sql_identifier
    array:array
} -validate {
    less_than_zero -requires {neg_int:integer} {
	if { $neg_int >= 0 } {
	    ad_complain 
	}
    }
} -errors {
    {less_than_zero neg_int:,integer} {The value entered for <b>Negative Integer</b> must be an integer less than zero.}
    int:,integer {The <b>Integer</b> value must be a valid integer}
} 

doc_body_append "[ad_header "Test Harness Results for ad_page_contract"]

<h2>Test Harness Results</h2>

for <code>ad_page_contract</code>

<hr>

<em>All input was valid.</em>

<blockquote>
<table>

<tr>
<th align=right>Non-HTML string:</th>
<td>$str</td>
</tr>

<tr>
<th align=right>HTML string:</th>
<td>[ns_quotehtml $html_str]</td>
</tr>

<tr>
<th align=right>Arbitrary HTML string:</td>
<td>[ns_quotehtml $any_html_str]</td>
</tr>

<tr>
<th align=right>Integer:</td>
<td>$int</td>
</tr>

<tr>
<th align=right>Negative Integer:</td>
<td>$neg_int</td>
</tr>

<tr>
<th align=right>SQL Identifier:</td>
<td>$sql_identifier</td>
</tr>

<tr>
<th align=right>Array:</td>
<td>array(foo)=$array(foo)<br>array(bar.greble)=$array(bar.greble)</td>
</tr>

</table>
</blockquote>

[ad_footer]
"


