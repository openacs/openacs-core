ad_page_contract { 
    return x-editlocal or the code for the compiled function
} {
    {fname:trim {}}
    {code:trim {}}
    {output:trim {}}
}
ds_require_permission [ad_conn package_id] "admin"

if {$code ne ""} { 
    if {[regexp {(.*)\.(adp)} $code match stub ext]} { 
        ns_return 200 text/plain [info body ::template::code::${ext}::$stub]
    } else { 
        ns_returnfile 200 text/plain $code
    }
} elseif {$fname ne ""} {
    ns_return 200 application/x-editlocal [ns_set get [ns_conn form] fname]
} elseif {$output ne ""} { 
    if {[regexp {[0-9]+:error} $output]} { 
        if {[ns_cache get ds_page_bits $output content]} { 
            foreach error $content { 
                append out "PAGE: [lindex $error 0]\n[string repeat - 60]\n[lindex $error 1]\n\n\n"
            }
            ns_return 200 text/plain $out
        }
    } else { 
        if {[ns_cache get ds_page_bits $output content]} { 
            ns_return 200 text/plain "Size: [string length $content]\n\n------------------------------------------------------------\n$content"
        } else { 
            ns_return 200 text/plain "Output for $output has expired"
        }
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
