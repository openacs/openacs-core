ad_page_contract {
    Control page for an individual server.
} {
    name:notnull
}

parse_test_server_file -name $name -array service

set page_title "Control Page For $service(name)"
set context [list $page_title]

