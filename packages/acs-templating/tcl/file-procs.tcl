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
    return [template::util::file_transform $element(id)]
}

ad_proc -public template::util::file_transform { element_id } {

    Helper proc, which gets AOLserver/NaviServer's variables from the
    query/form, and returns it as a 'file' datatype value.

    @return the list { file_name temp_file_name content_mime_type }.

} {
    #
    # Check if these have already been converted, then return them as they are.
    #
    # This may happen, for instance, during the 'preview' action of a form.
    #
    if { [ns_queryget $element_id.tmpfile] eq "" } {
        set files [ns_querygetall $element_id]
    } else {
        if {[ns_info name] eq "NaviServer"} {
            #
            # NaviServer
            #
            # Get the files information using 'ns_querygetall'
            #
            set filenames [ns_querygetall $element_id]
            set tmpfiles  [ns_querygetall $element_id.tmpfile]
            set types     [ns_querygetall $element_id.content-type]
        } else {
            #
            # AOLserver
            #
            # ns_querygetall behaves differently in AOLserver, using the ns_queryget
            # legacy version instead
            #
            set filenames [ns_queryget $element_id]
            set tmpfiles  [ns_queryget $element_id.tmpfile]
            set types     [ns_queryget $element_id.content-type]
        }
        #
        # No files, get out
        #
        if {$filenames eq ""} {
            return ""
        }
        #
        # Return the files info in a list per file
        #
        set files [list]
        for {set file 0} {$file < [llength $filenames]} {incr file} {
            set filename [lindex $filenames $file]
            set tmpfile  [lindex $tmpfiles $file]
            set type     [lindex $types $file]
            #
            # Cleanup filenames
            #
            regsub -all -- {\\+} $filename {/} filename
            regsub -all -- { +} $filename {_} filename
            set filename [lindex [split $filename "/"] end]
            #
            # Append to the list of lists
            #
            lappend files [list $filename $tmpfile $type]
        }
    }

    return $files

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

    switch -- $what {
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
