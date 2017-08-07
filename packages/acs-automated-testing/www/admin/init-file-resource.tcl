ad_page_contract {
  Re-source a test init file with test case definitions to
  avoid server restart.

  @author Peter Marklund

  @cvs-id $Id$
} {
    absolute_file_path
    return_url:localurl
}

ns_log Notice "Sourcing test definition file $absolute_file_path"
apm_source $absolute_file_path

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
