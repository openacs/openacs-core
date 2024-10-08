ad_page_contract {
} -properties {
    __form_contents__:multirow
}

set __return_url__ [ad_conn url]

# The basic idea here is to build a multirow holding the form contents, which then get
# passed back to the form handler transparently as a submission, as though the confirm
# step never happened.

# There's one exception - we set the special form element "__confirmed_p" true.  This
# informs ad_form that the user has indeed confirmed the submission.

multirow create __form_contents__ __key__ __value__

if { [set __form__ [ns_getform]] ne "" } {

    foreach __key__ [ns_set keys $__form__] {
        if { $__key__ eq "__confirmed_p" } {
            multirow append __form_contents__ __confirmed_p 1
        } else {
	    foreach __value__ [ns_querygetall $__key__] {
		multirow append __form_contents__ $__key__ $__value__
	    }
        }
    }

}

template::add_body_script -script [subst {
    document.getElementById('confirm-button').addEventListener('click', function (event) {
        event.preventDefault();
        history.back();
        return false;
    });
    document.getElementById('confirm-button').addEventListener('keypress', function (event) {
        event.preventDefault();
        acs_KeypressGoto(document.referrer,event);
        return false;
    });
}]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
