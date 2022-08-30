ad_library {

    Tests for api in tcl/dimensional-procs.tcl

}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    ad_dimensional
    ad_dimensional_sql
    template::adp_compile
    template::adp_eval
    ad_looks_like_html_p
} ad_dimensional {
    Test ad_dimensional
} {
    aa_section ad_dimensional

    set dimensional_list {
        {
            show_methods "Methods:" 1 {
                { 2 "All Methods" }
                { 1 "Documented Methods" }
                { 0 "Hide Methods" }
            }
        }
        {
            show_source "Source:" 0 {
                { 1 "Display Source" }
                { 0 "Hide Source" }
            }
        }
        {
            show_variables "Variables:" 0 {
                { 1 "Show Variables" }
                { 0 "Hide Variables" }
            }
        }
    }

    #
    # ad_dimensional can only be invoked in the context of an
    # adp_template
    #
    set template [template::adp_compile -string {
        <% set d [ad_dimensional $dimensional_list] %>
        @d;noquote@
    }]
    set dimensional_slider [template::adp_eval template]

    aa_true "The slider is HTML" [ad_looks_like_html_p $dimensional_slider]
    foreach e $dimensional_list {
        lassign $e v t d spec
        aa_true "Slider contains the title '$t'" {[string first $t $dimensional_slider] >= 0}
        foreach s $spec {
            lassign $s spec_v spec_l
            aa_true "Slider contains the label '$spec_l'" \
                {[string first $spec_l $dimensional_slider] >= 0}
            if {$spec_v != $d} {
                #
                # There is no link for the default value of a filter
                #
                aa_true "Slider contains '$v=$spec_v'" \
                    {[string first $v=$spec_v $dimensional_slider] >= 0}
            }
        }
    }

    aa_section ad_dimensional_sql

    set options_set [ns_set create]
    ns_set put $options_set show_variables 1
    ns_set put $options_set show_methods 2
    ns_set put $options_set bogus irrelevant
    set sql_filters [ad_dimensional_sql $dimensional_list where and $options_set]
    aa_equals "The dimensional_list has no where clauses, the result must be empty" \
        $sql_filters ""

    aa_log "Create new dimensional_list with clauses"
    set dimensional_list {
        {
            show_methods "Methods:" 1 {
                { 2 "All Methods" {where "one"}}
                { 1 "Documented Methods" {where "two"}}
                { 0 "Hide Methods" {where "three"}}
            }
        }
        {
            show_source "Source:" 0 {
                { 1 "Display Source" {where "a"}}
                { 0 "Hide Source" {where "b"}}
            }
        }
        {
            show_variables "Variables:" 0 {
                { 1 "Show Variables" {where "1"}}
                { 0 "Hide Variables" {where "2"}}
            }
        }
    }

    set sql_filters [ad_dimensional_sql $dimensional_list where and $options_set]
    aa_equals "The dimensional_list has the expected value" \
        $sql_filters " and one and b and 1"

    set sql_filters [ad_dimensional_sql $dimensional_list where the_separator $options_set]
    aa_equals "The dimensional_list has the expected value" \
        $sql_filters " the_separator one the_separator b the_separator 1"

}

