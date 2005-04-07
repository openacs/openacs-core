ad_page_contract {
    This display the anonymous assessments available for registration
    
    @author Vivian Hernandez (vivian@viaro.net) Viaro Networks (www.viaro.net)
    @creation-date 2005-01-20
    @cvs-id $Id: 
} {
    assessment_id:optional
}


if {![exists_and_not_null assessment_id]} {
    set value [parameter::get -parameter AsmForRegisterId]
    set assessment_id $value
}
set install_p [apm_package_installed_p "assessment"]
set mount_p [site_node::get_package_url -package_key assessment]
if {$install_p == 0 || $mount_p == ""} {
    ad_return_complaint 1 "Assessment Package is not installed or mounted"
    ad_script_abort
}
set url ""

set instance_id [ db_list_of_lists get_instance_id {}]
set new_url [apm_package_url_from_id [lindex $instance_id 0]]
set instance_name [ad_conn instance_name] 
set page_title "$instance_name [_ acs-subsite.set_reg_asm]"

set context [list "[_ acs-subsite.set_reg_asm]"]

set subsite_id [ad_conn subsite_id]



set assessments [db_list_of_lists get_all_assessments {}]
lappend assessments [list "[_ acs-subsite.none]" 0]


set asm_p [llength $assessments]

ad_form -name get_assessment  -form {
    {assessment_id:text(select)
	{label "[_ acs-subsite.choose_assessment]"}
	{options $assessments}
	{help_text "[_ acs-subsite.choose_assessment_help]"}
	{value $assessment_id}}
    {submit:text(submit)
	{label "   OK   "}}
        {edit:text(submit)
	{label "[_ acs-subsite.edit_asm]"}}
} -after_submit {
    if {![empty_string_p $edit]} {
	if { $assessment_id != 0} {
	    if { ![string eq $assessment_id 0]} {
		set package_id [db_string package_id {}]
		set url [apm_package_url_from_id $package_id]
	    }
	    ad_returnredirect "${url}asm-admin/one-a?assessment_id=$assessment_id&reg_p=1"
	}
    }  else {
	parameter::set_value -package_id [ad_conn package_id] -parameter AsmForRegisterId -value $assessment_id
	ad_returnredirect ""
    }
}

ad_return_template












































