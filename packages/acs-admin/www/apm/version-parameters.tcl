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
		   [list description "Description" {} {<td>[ad_quotehtml $description]</td>}]]

#DRB: sql_clauses must not contain RDBMS-specific query clauses.
set sql_clauses ""

if { [exists_and_not_null dimensional_list] } {
    lappend table_def [list section_name "Section:"]
    append sql_clauses [ad_dimensional_sql $dimensional_list]
}

lappend table_def [list parameter_id "Actions" no_sort \
		       {<td>\[<font size=-1>
	     <a href=parameter-delete?[export_url_vars parameter_id version_id]>delete</a> | 
			  <a href=parameter-edit?[export_url_vars version_id parameter_id]>edit</a></font>\] 
			   </td>}]

append sql_clauses [ad_order_by_from_sort_spec $orderby $table_def]

doc_body_append "[apm_header [list "version-view?version_id=$version_id" "$pretty_name $version_name"] "Parameters"]
<blockquote>
"

if { ![empty_string_p $dimensional_list] } {
    doc_body_append "[ad_dimensional $dimensional_list]<p>"
}

doc_body_append "[ad_table -Torderby $orderby \
     -bind [ad_tcl_vars_to_ns_set version_id package_key] \
     -Textra_vars {version_id} \
     -Tmissing_text "No parameters registered in this section." \
		     parameter_table "" $table_def]
<br><a href=parameter-add?[export_url_vars version_id]>Add a new parameter</a>

</blockquote>
[ad_footer]
"









