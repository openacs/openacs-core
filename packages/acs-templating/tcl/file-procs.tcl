namespace eval template {}
namespace eval template::data {}
namespace eval template::data::transform {}
namespace eval template::data::validate {}
namespace eval template {}
namespace eval template::util {}
namespace eval template::util::file {}


ad_proc -public template::data::transform::file { element_ref } {
    @return the list { file_name temp_file_name content_mime_type }.
} {
    upvar $element_ref element
    set element_id $element(id)

    # Work around Windows bullshit
    set filename [ns_queryget $element_id]

    if { [string equal $filename ""] } {
        return ""
    }

    regsub -all {\\+} $filename {/} filename
    regsub -all { +} $filename {_} filename
    set filename [lindex [split $filename "/"] end]
    return [list [list $filename [ns_queryget $element_id.tmpfile] [ns_queryget $element_id.content-type]]]

}

ad_proc -public template::data::validate::file { value_ref message_ref } {
    Our file widget can't fail 

    @return true
} {
    return 1
}

ad_proc -public template::util::file::get_property { what file_list } {

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
