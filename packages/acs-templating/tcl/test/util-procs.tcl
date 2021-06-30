ad_library {
    Automated tests for template::util

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
    @cvs-id $Id$
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::util::number_list
} number_list {
    Test template::util::number_list

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
} {
    set lists {
        {0 5} {0 1 2 3 4 5}
        {0 0} {0}
        {9 20} {9 10 11 12 13 14 15 16 17 18 19 20}
        {9999999 10000000} {9999999 10000000}
        {1 0} {}
        {-1 1} {-1 0 1}
    }
    dict for {value result} $lists {
        set start_at    [lindex $value 0]
        set last_number [lindex $value 1]
        aa_equals "List from $start_at to $last_number" \
            [template::util::number_list $last_number $start_at] \
            $result
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::util::nvl
} nvl {
    Test template::util::nvl

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
} {
    set values_result {
        {0 5} 0
        {"" la} la
        {"" ""} {}
        {this not} this
        {this ""} this
    }
    dict for {values result} $values_result {
        set value           [lindex $values 0]
        set value_if_nil    [lindex $values 1]
        aa_equals "Value: $value, if nil: $value_if_nil" \
            [template::util::nvl $value $value_if_nil] \
            $result
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::util::get_url_directory
} get_url_directory {
    Test template::util::get_url_directory

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
} {
    set url_dirs {
        // //
        /test /
        /test/ /test/
        /test/foo/bar /test/foo/
        /test/foo/bar/ /test/foo/bar/
    }
    dict for {url dir} $url_dirs {
        aa_equals "Url: $url, directory: $dir" \
            [template::util::get_url_directory $url] \
            $dir
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
