ad_page_contract {
    List all the files in a particular version of a package.

    @param version_id The package to be processed.
    @author tnight@arsdigita.com
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 12 September 2000
    @cvs-id $Id$
} {
    {orderby:token "parameter_name"}
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

if { $dimensional_list ne "" } {
    append sql_clauses [ad_dimensional_sql $dimensional_list]
    lappend elements_list section_name {
        label "Section"
        orderby section_name
    }
}

lappend elements_list actions {
    label "Actions"
    display_template {
        <a href="@parameters.parameter_edit_url@"><adp:icon name="edit" title="Edit Parameter Definition"></a>&nbsp;
        <a href="@parameters.parameter_delete_url@"><adp:icon name="trash" title="Delete Parameter"></a>
    }
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

db_multirow -extend {parameter_delete_url parameter_edit_url} parameters parameter_table {} {
    set parameter_delete_url [export_vars -base parameter-delete {parameter_id version_id section_name}]
    set parameter_edit_url [export_vars -base parameter-edit {version_id parameter_id}]
}



set page_title "Parameters"
set context [list \
                 [list "." "Package Manager"] \
                 [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] \
                 $page_title]

set filter_html ""
if { $dimensional_list ne "" } {
    set filter_html [ad_dimensional $dimensional_list]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
