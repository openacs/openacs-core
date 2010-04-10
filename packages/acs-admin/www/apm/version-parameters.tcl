ad_page_contract { 
    List all the files in a particular version of a package.

    @param version_id The package to be processed.
    @author tnight@arsdigita.com
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 12 September 2000
    @cvs-id $Id$
} {
    {orderby ""}
    {version_id:integer}
    {section_name ""}
}

db_1row apm_package_by_version_id {
    select pretty_name, version_name, package_key
      from apm_package_version_info 
     where version_id = :version_id
}


set dimensional_list [apm_parameter_section_slider $package_key]

set table_def [list \
		   [list  parameter_name "Parameter"] \
		   [list datatype "Type"] \
                   [list scope "Scope"] \
		   [list description "Description" {} {<td>[ad_quotehtml $description]</td>}]]

#DRB: sql_clauses must not contain RDBMS-specific query clauses.
set sql_clauses ""

if { [exists_and_not_null dimensional_list] } {
    lappend table_def [list section_name "Section:"]
    append sql_clauses [ad_dimensional_sql $dimensional_list]
}

lappend table_def [list parameter_id "Actions" no_sort \
		       {<td>\[<font size=-1>
	     <a href=parameter-delete?[export_url_vars parameter_id version_id section_name]>delete</a> | 
			  <a href=parameter-edit?[export_url_vars version_id parameter_id]>edit</a></font>\] 
			   </td>}]

append sql_clauses [ad_order_by_from_sort_spec $orderby $table_def]

set page_title "Parameters"
set context [list [list "." "Package Manager"] [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] $page_title]

append body "
<blockquote>
"

if { $dimensional_list ne "" } {
    append body "[ad_dimensional $dimensional_list]<p>"
}

# LARS hack
set sections [lindex [lindex $dimensional_list 0] 3]
foreach section $sections {
    if {$section_name eq [lindex $section 0]} {
        set section_name [lindex $section 1]
        break
    }
}

set parent_package_keys [lrange [apm_one_package_inherit_order $package_key] 0 end-1]

append body "[ad_table -Torderby $orderby \
     -bind [ad_tcl_vars_to_ns_set version_id package_key parent_package_keys] \
     -Textra_vars {version_id} \
     -Tmissing_text "No parameters registered in this section." \
		     parameter_table "" $table_def]
<br><a href=parameter-add?[export_url_vars version_id section_name]>Add a new parameter</a>

</blockquote>
"









