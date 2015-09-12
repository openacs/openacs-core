ad_library {

    Library for managing language codes

    @author Emmanuelle Raffenne (eraffenne@gmail.com)
}

namespace eval ref_language {}

ad_proc -public ref_language::set_data {
    -label:required
    {-iso1 ""}
    {-iso2 ""}
} {
    Add new ISO-639 language codes (3 chars and 2 chars) where they don't exist, 
    update them otherwise.
} {

    if { $iso1 eq "" && $iso2 eq "" } {

        error "you need to provide either a 2 chars or a 3 chars language code"

    } else {

        if { $iso2 ne "" } {
            set exists_p [db_string get_lang {} -default 0]

            if { $exists_p } {
                db_dml update_lang {}
            } else {
                db_dml insert_lang {}
            }
        }

        if { $iso1 ne "" } {
            ref_language::set_iso1 -code $iso1 -name $label
        }
    }

}

ad_proc -private ref_language::set_iso1 {
    -code:required
    -name:required
} {
    Add a new ISO-639-1 language code (2 chars) if it doesn't exist, 
    update it otherwise
} {

    set exists_p [db_string get_lang {} -default 0]

    if { $exists_p } {
        db_dml update_lang {}
    } else {
        db_dml insert_lang {}
    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
