ad_page_contract {
    Adds a parameter to a version.
    @author Todd Nightingale [tnight@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    parameter_id:notnull,naturalnum
    version_id:notnull,naturalnum
}


set user_id [ad_conn user_id]

db_1row param_info { 
    select parameter_name, datatype, description, default_value, min_n_values, max_n_values, parameter_id, 
    section_name, default_value
      from apm_parameters
     where parameter_id = :parameter_id
}

db_1row apm_get_name { 
    select pretty_name, version_name, package_key
      from apm_package_version_info
     where version_id = :version_id
}

db_release_unused_handles

set page_title "Edit Parameter"
set context [list [list "." "Package Manager"] [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] [list [export_vars -base version-parameters { version_id }] "Parameters"] $page_title]

append body "
<form action=\"parameter-edit-2\" method=\"post\">
<blockquote>
<table>
[export_form_vars package_key parameter_id version_id]

<tr>
  <td></td>
  <td>A parameter can be used to store information that is specific to a package but that needs to
be easily configurable and customized on a package instance basis.  The name should be a brief 
plain text string that identifies the parameter.
  </td>
</tr>

<tr>
  <th align=right nowrap>Parameter Name:</th>
  <td><input name=parameter_name size=50 value=\"[ad_quotehtml $parameter_name]\"></td>
</tr>

<tr>
  <td></td>
  <td>Type a description of your parameter.
</tr>

<tr valign=top>
  <th align=right><br>Description:</th>
  <td><textarea name=description cols=60 rows=8>[ad_quotehtml $description]</textarea>
</td>
</tr>

<tr>
  <td></td>
  <td>You may enter a section name to identify the parameter.  For example, the ACS Kernel has a \"security\" section
to indicate which parameters pertain to security.
</tr>

<tr valign=top>
  <th align=right><br>Section Name:</th>
  <td><input name=section_name value=\"[ad_quotehtml $section_name]\" size=50><br>
</td>
</tr>


<tr>
  <td></td>
  <td>Please indicate what type of parameter it is.  
</tr>

<tr>
  <th align=right nowrap>Type:</th>
  <td><select name=datatype>
      [ad_generic_optionlist {number string} {number string} $datatype]
      </select>
  </td>
</tr>

<tr>
  <td></td>
  <td>The default setting will be the parameter value that applies to any package instance that does
  not set its own value.
  </td>
</tr>

<tr>
  <th align=right nowrap>Default:</th>
  <td><input name=default_value size=50 value=\"[ad_quotehtml $default_value]\"></td>
</tr>

<tr><th colspan=2><input type=submit value=\"Edit Parameter\"></th>
</tr>
</table>
</blockquote>
</form>
[ad_footer]
"



