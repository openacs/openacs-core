# /www/admin/acceptance-tests/tcl-documentation.tcl
#
# Test page for the tcl documentation procs
#
# ron@arsdigita.com, Tue Jul 25 01:41:50 2000
#
# $Id$

proc ::print_result { filter value expected result status } {
    return "
    <tr>
    <td>$filter</td>
    <td>[ns_quotehtml $value]</td>
    <td align=right><code>$expected</code></td>
    <td align=right><code>$result</code></td>
    <td align=right><code>$status</code></td>
    "
}

# Test a filter for either success or failure.  If valid_p = 1 then
# the filter is expected to success and we should get back result ==
# value.  Otherwise the filter should fail and we should get back the
# empty string.

proc ::filter_test { filter value {expected 1}} {
    set result [ad_page_contract_filter_invoke $filter var value]

    # What did we get?

    if [string equal $result $expected] {
	ns_write "[print_result $filter $value $expected $result ok]\n"
    } else {
	ns_write "[print_result $filter $value $expected $result failed]\n"
    }
}

# wrapper for a filter that is expected to succeed

proc ::filter_success { filter value } {
    filter_test $filter $value 1
}

# wrapper for a filter that is expected to fail

proc ::filter_failure { filter value } {
    filter_test $filter $value 0
}

# -----------------------------------------------------------------------------

ReturnHeaders

ns_write "
<html>
<head>
<title>Input Filter Acceptance Tests</title>
</head>
<body bgcolor=white>

<h2>Input Filter Acceptance Tests</h2>

for the OpenACS Community System
<hr>

<p>This page applies a suite of tests for the ad_page_contract filters.</p>

<blockquote>
<table cellpadding=2>
<tr>
<th align=left>Filter</th>
<th>Value</th>
<th>Expected</th>
<th>Actual result</th>
<th>Status</th>
</tr>
"

filter_success integer  1
filter_failure integer  a
filter_failure integer  1.2
filter_failure integer  '
	       
filter_success naturalnum 1
filter_failure naturalnum -1
filter_failure naturalnum  a
filter_failure naturalnum  1.2
filter_failure naturalnum  '

filter_success html     '
filter_success html    <p>
	       
filter_success nohtml   a
filter_failure nohtml  <p>

ns_write "
</table>
</blockquote>

<p>Done.  If any of the above tests failed, please submit a bug report
to the <a
href=http://openacs.org/sdm/>OpenACS Software Development Manager</a>.  
Note that you are running OpenACS [ad_acs_version] released
on [ad_acs_release_date].</p> 

<hr>
<address>bugs@openacs.org</address>
</body>
</html>

"
