ad_page_contract { 
    Display the values of all parameters associated with a versionList all the files in a particular version of a package.

    @param version_id The package to be processed.
    @author kevin@caltech.edu
    @creation-date 17 May 2000
    @cvs-id $Id$
} {
    { version_id:integer }
}


db_1row apm_package_by_version_id {
    select package_name, version_name, package_id from apm_package_version_info where version_id = :version_id
}

doc_body_append [apm_header [list "version-view?version_id=$version_id" "$package_name $version_name"] "Parameter Values"]

doc_body_append "
<table>
"

set first_iteration 1

db_foreach apm_all_elements {
select element_id, element_name, description
from   ad_parameter_elements
where  version_id = :version_id
order by element_name
} {

    if {$first_iteration} {
	doc_body_append "
	<tr>
	 <th>Parameter</th>
	 <th>Description</th>
	 <th>Value</th>
	</tr>
	"
    }
    set first_iteration 0

    doc_body_append "
    <tr>
    <td valign=top><a href=parameter-value?element_id=$element_id>[ns_quotehtml $element_name]</a></td>
    <td valign=top>$description</td>
    <td valign=top>"
    doc_body_append [join [map ns_quotehtml [db_list apm_value {
	select value from ad_parameter_values where element_id = :element_id
    }]] "<br>"]
    
    doc_body_append "</td>
    </tr>
    "

}

doc_body_append "
</table>

[ad_footer]"

    
