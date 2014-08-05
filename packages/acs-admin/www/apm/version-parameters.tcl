ad_page_contract { 
    List all the files in a particular version of a package.

    @param version_id The package to be processed.
    @author tnight@arsdigita.com
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 12 September 2000
    @cvs-id $Id$
} {
    {orderby "parameter_name"}
    {version_id:naturalnum,notnull}
    {section_name ""}
}

db_1row apm_package_by_version_id {
    select pretty_name, version_name, package_key
    from apm_package_version_info 
    where version_id = :version_id
}


set dimensional_list [apm_parameter_section_slider $package_key]

set elements_list {
    parameter_name {
        label "Parameter"
        orderby parameter_name
    }
    datatype {
        label "Type"
        orderby datatype
    }
    scope {
        label "Scope"
        orderby scope
    }
    description {
        label "Description"
        orderby description
    }    
}

#DRB: sql_clauses must not contain RDBMS-specific query clauses.
set sql_clauses ""

if { ([info exists dimensional_list] && $dimensional_list ne "") } {
    append sql_clauses [ad_dimensional_sql $dimensional_list]
    lappend elements_list section_name {
        label "Section"
        orderby section_name
    }
}

lappend elements_list actions {
    label "Actions"
    display_template { @parameters.actions;noquote@ }
}

template::list::create -name parameters_list \
    -multirow parameters \
    -key parameter_name \
    -no_data "No parameters registered in this section." \
    -actions [list "Add new parameter" [export_vars -base parameter-add {version_id section_name}] "Add new parameter"] \
    -elements $elements_list \
    -filters {version_id {} section_name {}}

set parent_package_keys [lrange [apm_one_package_inherit_order $package_key] 0 end-1]
append sql_clauses " [template::list::orderby_clause -orderby -name parameters_list]"

db_multirow -extend {actions} parameters parameter_table {} {
    set actions "\[<font size=-1>
        <a href=parameter-delete?[export_vars -url {parameter_id version_id section_name}]>delete</a> | 
        <a href=parameter-edit?[export_vars -url {version_id parameter_id}]>edit</a></font>\]"
}



set page_title "Parameters"
set context [list [list "." "Package Manager"] [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] $page_title]

set filter_html ""
if { $dimensional_list ne "" } {
    set filter_html [ad_dimensional $dimensional_list]
}

# LARS hack
set sections [lindex $dimensional_list 0 3]
foreach section $sections {
    if {$section_name eq [lindex $section 0]} {
        set section_name [lindex $section 1]
        break
    }
}





