ad_page_contract {
    Adds a parameter to a version.
    @author Todd Nightingale [tnight@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    version_id:naturalnum,notnull
    {section_name ""}
    {parameter_name ""}
    {description ""}
    {default_value ""}
    {scope ""}
    {return_url ""}
}

set user_id [ad_conn user_id]

set parameter_id [db_nextval acs_object_id_seq]
db_1row apm_get_name {
    select package_key, pretty_name, version_name
    from apm_package_version_info
    where version_id = :version_id
}

# This to filter out sections such as "all" and $package_key, which
# have special meaning and are not supposed to be created.
if {![db_string get_section {
    select case when exists (select 1 from apm_parameters
                             where section_name = :section_name
                             and package_key = :package_key) then 1 else 0 end from dual}]} {
    set section_name ""
}

set title "Add Parameter"
set context [list \
		 [list "." "Package Manager"] \
		 [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] \
		 [list [export_vars -base version-parameters { version_id }] "Parameters"] \
		 $title]

#
# GN: The code below should be replaced by ad_form
#
append body [subst {
<form action="parameter-add-2" method="post">
<blockquote>
<table>
[export_vars -form {package_key parameter_id version_id return_url}]

<tr>
  <td></td>
  <td>A parameter can be used to store information that is specific to a package but that needs to
be easily configurable and customized.  The name should be a brief 
plain text string that identifies the parameter.
  </td>
</tr>

<tr>
  <th align="right" nowrap>Parameter Name:</th>
  <td><input name="parameter_name" size="50" value="[ns_quotehtml $parameter_name]"></td>
</tr>

<tr>
  <td></td>
  <td>Description of the new parameter.
</tr>

<tr valign="top">
  <th align="right"><br>Description:</th>
  <td><textarea name="description" cols="60" rows="8">[ns_quotehtml $description]</textarea>
</td>
</tr>


<tr>
  <td></td>
  <td>You may enter a section name to identify the parameter.  
   For example, the ACS Kernel has a "security" section
   to indicate which parameters pertain to security.
</tr>

<tr valign="top">
  <th align="right"><br>Section Name:</th>
<td><input name="section_name" size="50" value="[ns_quotehtml $section_name]"><br>
</td>
</tr>

<tr>
  <td></td>
  <td>Please indicate if the parameter is of "global" (has one system-wide value) 
      or "instance" (a value for each package instance) scope.<br>
  </td>
</tr>

<tr>
  <th align="right" nowrap>Scope:</th>
  <td><select name="scope">
[ad_generic_optionlist {instance global} {instance global} $scope]
      </select>
  </td>
</tr>

<tr>
  <td></td>
  <td>Please indicate what type of parameter it is.  
</tr>

<tr>
  <th align="right" nowrap>Type:</th>
  <td><select name="datatype">
[ad_generic_optionlist {number string textarea} {number string text} string]
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
  <td><input name="default_value" size="50" value="[ns_quotehtml $default_value]"></td>
</tr>

<tr><th colspan="2"><input type="submit" value="Add Parameter"></th>
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
