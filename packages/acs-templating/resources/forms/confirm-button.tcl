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

if { ![empty_string_p [set __form__ [ns_getform]]] } {

    set __form_size__ [ns_set size $__form__]
    set __form_counter__ 0
   
    while { $__form_counter__ < $__form_size__ } {
        if { [string equal [ns_set key $__form__ $__form_counter__] __confirmed_p] } {
            multirow append __form_contents__ __confirmed_p 1
        } else {

	    set __key__ [ns_set key $__form__ $__form_counter__]
	    set __values__ [ns_querygetall $__key__]

	    foreach __value__ $__values__ {
		multirow append __form_contents__ $__key__ $__value__
	    }

        }
        incr __form_counter__
    }

}
