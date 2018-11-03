
# Decide, whether we want to include calling-info based on static
# analysis in the procdoc structure (what function calls what other
# functions). This calling-info is just relevant for developer
# instances. The computation of the calling-info is not blazingly
# fast, so just do it when needed.
#
# To activate the computation of calling-info, add a section like the
# following to your NaviServer config file. Note that the
# calling-info is not necessarily complete (it is not always possible
# to derive call calls from the static analysis), also direct calls
# from web pages are not included.
#
# ns_section ns/server/${server}/acs/acs-api-browser
#         ns_param IncludeCallingInfo true
#
if {[parameter::get \
	 -package_id [apm_package_id_from_key acs-api-browser] \
	 -parameter IncludeCallingInfo \
	 -default false]} {
    ad_schedule_proc -thread t -once t 1 ::api_add_calling_info_to_procdoc
}


