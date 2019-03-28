ad_page_contract {

    A quick and dirty test page for signed cookies. sets a signed cookie
    with a known secret as well as one with an unknown secret.

    @author Richard Li (richardl@arsdigita.com)
    @cvs-id $Id$
    @creation-date 19 October 2000

} 

# known secret
ad_set_signed_cookie -secret "hello" -max_age 1 -token_id 1 testcookie "as,df"
# random secret
ad_set_signed_cookie -max_age 1 testcookie2 "lots,of,,commas"

ns_return 200 text/html "
[ad_header "Signed Cookies Test Page"]


cookies set. <a href=\"signed-cookies-test-2\">test it out</a>.

[ad_footer]"