ad_page_contract {

    Set parameters on a package instance.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 12 September 2000
    @cvs-id $Id$

} {
    package_id:naturalnum,notnull
    {orderby ""}
    {return_url "."}
}

ad_require_permission $package_id admin

db_1row package_info {}

set table_def [list \
		   [list parameter_name "Parameter Name"] \
		   [list description "Description"]]

set table_sql "select p.parameter_id, p.parameter_name, p.package_key, nvl(p.description, 'No Description') description,
	 nvl(v.attr_value, 'No Value') attr_value, nvl(p.section_name, 'No Section Name') section_name
	from apm_parameters p, (select parameter_id, attr_value 
				from apm_parameter_values v 
				where v.package_id = :package_id) v
	where p.parameter_id = v.parameter_id(+)
	and p.package_key = (select package_key from apm_packages where package_id = :package_id)"

set dimensional_list [apm_parameter_section_slider $package_key]
set additional_sql ""

if {[exists_and_not_null dimensional_list] } {
    lappend table_def [list section_name "Section:"]
    append additional_sql [ad_dimensional_sql $dimensional_list]
    ns_log Notice [ad_dimensional_sql $dimensional_list]
}

# DRB: This should be rewritten to optionally allow for the definition of possible parameter values,
# with a drop-down select widget used rather than a text input widget. 

# TIL: only show the from-file-parameter-warning when there are
# actually parameters from a file in this listing.
set display_warning_p 0

lappend table_def [list attr_value "Value" no_sort \
	{<td>
	   <input name=params.$parameter_id value=\"$attr_value\" size=50>
	    <font color=red><strong>[if { ![empty_string_p [ad_parameter_from_file $parameter_name [uplevel set package_key]]] } { uplevel set display_warning_p 1 } ; ad_parameter_from_file $parameter_name [uplevel set package_key]]</strong></font>
	    </td>}]

append additional_sql [ad_order_by_from_sort_spec $orderby $table_def]

set body "[ad_header "Parameters for $instance_name"]
<h2>Parameters for $instance_name</h2>
[ad_context_bar [list "index" "Site Map"] "$instance_name Parameters"]
<hr>
"

if { ![empty_string_p $dimensional_list] } {
    append body "[ad_dimensional $dimensional_list]<p>"
}

append table_sql $additional_sql

ns_log Notice "table_sql = $table_sql"

set table [ad_table -Torderby $orderby \
     -bind [ad_tcl_vars_to_ns_set package_id] \
     -Tmissing_text "No parameters registered in this section." \
     -Textra_rows "<tr>
<td></td><td></td>
<td><input type=submit value=\"Set Parameters\">
</td></tr>" parameter_table $table_sql $table_def]


if { $display_warning_p } {
    append body "
Note text in red below the parameter entry fields indicates the value of this
parameter is being overridden by an entry in the OpenACS parameter file.  The
use of the parameter file is discouraged but some sites need it to provide
instance-specific values for parameters independent of the apm_parameter
tables.
<hr>
"
}


ns_return 200 text/html "$body
<blockquote>
<form method=post action=parameter-set-2>
[export_form_vars package_key package_id instance_name return_url]
$table
</blockquote>
</form>
[ad_footer]
"
