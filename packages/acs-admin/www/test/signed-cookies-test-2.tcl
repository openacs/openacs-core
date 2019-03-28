ad_page_contract {

    A quick and dirty test page for signed cookies. Reads signed
    previously signed cookies and verifies. Also contains a set of
    regression tests for the secure_tokens ns_cache.a

    @author Richard Li (richardl@arsdigita.com)
    @cvs-id $Id$
    @creation-date 19 October 2000

} 

set cookie_value [ad_get_cookie testcookie]

set cookie_data [split $cookie_value {,}]
set cookie_data_length [llength $cookie_data]

set hash [lindex $cookie_data [expr {$cookie_data_length - 1}]]
set max_age [lindex $cookie_data [expr {$cookie_data_length - 2}]]
set token_id [lindex $cookie_data [expr {$cookie_data_length - 3}]]

if { $cookie_data_length == 4 } {
    # no commas in data
    set data [lindex $cookie_data 0]
} else {
    # join the data using commas
    set data [join [lrange $cookie_data 0 [expr {$cookie_data_length - 4}]] {,}]
}

set secret_token hello

set computed_hash [ns_sha1 "$data$token_id$max_age$secret_token"]

set list_of_names [ns_cache names secret_tokens]

set list_length [llength $list_of_names]

ReturnHeaders

ns_write "
[ad_header "signed cookies tests"]


<h1>Cookie Information</h1>

<ul>

<li>ad_get_signed_cookie returns: [ad_get_signed_cookie -secret "hello" testcookie]

<li>ad_get_signed_cookie returns for cookie 2: [ad_get_signed_cookie testcookie2]

<li>hash: '$hash'

<li>max_age: $max_age

<li>token_id: $token_id

<li>cookie_length: $cookie_data_length

<li>data: $data

<li>computed_hash: '$computed_hash'

<li>string compare: [string compare $computed_hash $hash]

</ul>

<h1>secret_token Cache Tests</h1>

<ul>

<li>cache is (check this to make sure the cache is getting populated):
$list_of_names

<li>cache size is (should be no greater than 100): $list_length"


if { $list_length > 80 && $list_length < 101 } {
    ns_write "<li>Success: cache size is between 80 and 100."
} else {
    ns_write "<li>Failure: cache size is incorrect. Verify default
    settings and try again."  
}



if { [lsearch -exact $list_of_names [sec_get_random_cached_token_id]] } {
    ns_write "<li>Success: random token is contained inside cache."
} else {
    ns_write "<li>Failure: random token is not in cache."
}

set token_id [sec_get_random_cached_token_id]
set token_value [sec_get_token $token_id]

set token_value_db [db_string get_token_value {
    select token from secret_tokens
    where token_id = :token_id
}]

if { $token_value eq $token_value_db  } {
    ns_write "<li>Success: sec_get_token test 1 passed."
} else {
    ns_write "<li>Failure: sec_get_token test 1 failed."
}

# do the same thing again to test the caching of tcl_
set token_value [sec_get_token $token_id]

if { $token_value eq $token_value_db  } {
    ns_write "<li>Success: sec_get_token test 2
    passed."
} else {
    ns_write "<li>Failure: sec_get_token test 2 failed."
}


ns_write "

</ul>

[ad_footer]

"