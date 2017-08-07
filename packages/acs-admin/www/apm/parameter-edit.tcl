ad_page_contract {
    Adds a parameter to a version.
    @author Todd Nightingale [tnight@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    parameter_id:notnull,naturalnum
    version_id:notnull,naturalnum
}

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

set title "Edit Parameter"
set context [list \
		 [list "." "Package Manager"] \
		 [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] \
		 [list [export_vars -base version-parameters { version_id }] "Parameters"] \
		 $title]

append body [subst {
<form action="parameter-edit-2" method="post">
<blockquote>
<table>
[export_vars -form {package_key parameter_id version_id}]

<tr>
  <td></td>
  <td>A parameter can be used to store information that is specific to a package but that needs to
be easily configurable and customized on a package instance basis.  The name should be a brief 
plain text string that identifies the parameter.
  </td>
</tr>

<tr>
  <th aligh="right" nowrap>Parameter Name:</th>
  <td><input name="parameter_name" size="50" value="[ns_quotehtml $parameter_name]"></td>
</tr>

<tr>
  <td></td>
  <td>Type a description of your parameter.
</tr>

<tr valign=top>
  <th aligh="right"><br>Description:</th>
  <td><textarea name="description" cols="60" rows="8">[ns_quotehtml $description]</textarea>
</td>
</tr>

<tr>
  <td></td>
  <td>You may enter a section name to identify the parameter.  For example, the ACS Kernel has a "security" section
to indicate which parameters pertain to security.
</tr>

<tr valign=top>
  <th aligh="right"><br>Section Name:</th>
  <td><input name="section_name" value="[ns_quotehtml $section_name]" size=50><br>
</td>
</tr>


<tr>
  <td></td>
  <td>Please indicate what type of parameter it is.  
</tr>

<tr>
  <th aligh="right" nowrap>Type:</th>
  <td><select name="datatype">
      [ad_generic_optionlist {number string "textarea"} {number string text} $datatype]
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
  <th aligh="right" nowrap>Default:</th>
<td><textarea name="default_value" cols="60" rows="[expr {$datatype eq "text" ? 8 : 1}]">[ns_quotehtml $default_value]</textarea>
</tr>

<tr><th colspan=2><input type="submit" value="Edit Parameter"></th>
</tr>
</table>
</blockquote>
</form>
}]

ad_return_template apm

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
