ad_page_contract {
    Testing translator mode.
}

set tcl_message [_ acs-lang.French]

set options [list]

foreach elm { English French German Spanish } {
    lappend options [list [_ acs-lang.$elm] $elm]
}

ad_form -name test -form {
    {lang:text(select)
        {label Language}
        {options $options}
    }
    {lang2:text(select)
        {label Language}
        {options $options}
    }
}

lang::message::register \
    en_US \
    acs-lang \
    Test_Contained_Message \
    "Contains message %contained_message% inside of it."

lang::message::register \
    [ad_conn locale] \
    acs-lang \
    Test_Contained_Message \
    "Contains message %contained_message% inside of it."

set contained_message [_ acs-lang.German]
set complete_message [_ acs-lang.Test_Contained_Message]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
