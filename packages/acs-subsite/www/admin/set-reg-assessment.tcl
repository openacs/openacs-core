ad_page_contract {
    This display the anonymous assessments available for registration
    
    @author Vivian Hernandez (vivian@viaro.net) Viaro Networks (www.viaro.net)
    @creation-date 2005-01-20
    @cvs-id $Id: 
}

set install_p [apm_package_installed_p "assessment"]
set mount_p [site_node::get_package_url -package_key assessment]

if {$install_p == 0 || $mount_p == ""} {
    ad_return_complaint 1 "Assessment Package is not installed or mounted"
    ad_script_abort
}

set page_title "[ad_conn instance_name] Set the assessment for registration"

set context [list "Set the assessment for registration"]

set subsite_id [ad_conn subsite_id]


set value [parameter::get -parameter AsmForRegisterId]


set assessments [db_list_of_lists get_all_assessments {}]
lappend assessments [list "[_ acs-subsite.none]" 0]


set asm_p [llength $assessments]

ad_form -name get_assessment  -form {
    {assessment_id:text(select)
    {label "[_ acs-subsite.choose_assessment]"}
    {options $assessments}
    {help_text "[_ acs-subsite.choose_assessment_help]"}
    {value $value}} 
} -on_submit {
    parameter::set_value -package_id [ad_conn package_id] -parameter AsmForRegisterId -value $assessment_id
}

ad_return_template












































