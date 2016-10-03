ad_library {
    File procs
}


namespace eval template {}
namespace eval template::data {}
namespace eval template::data::transform {}
namespace eval template::data::validate {}
namespace eval template {}
namespace eval template::util {}
namespace eval template::util::file {}

ad_proc -private template::data::transform::file { element_ref } {
    @return the list { file_name temp_file_name content_mime_type }.
} {
    upvar $element_ref element
    return [list [template::util::file_transform $element(id)]]
}

ad_proc -public template::util::file_transform { element_id } {
    Helper proc, which gets AOLserver's variables from the query/form, and returns it as a 'file' datatype value.
    @return the list { file_name temp_file_name content_mime_type }.
} {
    # Work around Windows bullshit
    set filename [ns_queryget $element_id]

    if {$filename eq ""} {
        return ""
    }

    regsub -all {\\+} $filename {/} filename
    regsub -all { +} $filename {_} filename
    set filename [lindex [split $filename "/"] end]
    return [list $filename [ns_queryget $element_id.tmpfile] [ns_queryget $element_id.content-type]]

}

ad_proc -public template::data::validate::file { value_ref message_ref } {
    Our file widget can't fail 

    @return true
} {
    return 1
}

ad_proc -public template::util::file::get_property {
    what
    file_list
} {
    Return a property from a file datatype structure.

    @param what Which property to return (filename, etc).
    @param file_list The file datatype structure.

    @return The requested property from the file datatype structure.
} {

    switch $what {
        filename {
            return [lindex $file_list 0]
        }
        tmp_filename {
            return [lindex $file_list 1]
        }
        mime_type {
            return [lindex $file_list 2]
        }
    }

}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
