ad_page_contract { 
    return x-editlocal or the code for the compiled function
} {
    {fname:trim {}}
    {code:trim {}}
}

if {![empty_string_p $code]} { 
    if {[regexp {(.*)\.(adp)} $code match stub ext]} { 
        ns_return 200 text/plain [info body ::template::code::${ext}::$stub]
    } else { 
        ns_returnfile 200 text/plain $code
    }
} else {
    ns_return 200 application/x-editlocal [ns_set get [ns_conn form] fname]
}
