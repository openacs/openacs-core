ad_page_contract {
    Adds a parameter to a version.
    @author Todd Nightingale [tnight@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    version_id:naturalnum,notnull
}

set user_id [ad_get_user_id]

db_1row apm_get_name { 
    select package_key, pretty_name, version_name, acs_object_id_seq.nextval as parameter_id
      from apm_package_version_info
     where version_id = :version_id
}
db_release_unused_handles

doc_body_append "[apm_header -form "action=parameter-add-2 method=post" [list "version-view?version_id=$version_id" "$pretty_name $version_name"] [list "version-parameters?[export_url_vars version_id]" "Parameters"] "Add a Parameter to $pretty_name ($version_name)" ]
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
  <td><input name=parameter_name size=50></td>
</tr>

<tr>
  <td></td>
  <td>Type a one-line description of your parameter.
</tr>

<tr valign=top>
  <th align=right><br>Description:</th>
  <td><input name=description size=50><br>
</td>
</tr>


<tr>
  <td></td>
  <td>You may enter a section name to identify the parameter.  For example, the ACS Kernel has a \"security\" section
to indicate which parameters pertain to security.
</tr>

<tr valign=top>
  <th align=right><br>Section Name:</th>
  <td><input name=section_name size=50><br>
</td>
</tr>


<tr>
  <td></td>
  <td>Please indicate what type of parameter it is.  
</tr>

<tr>
  <th align=right nowrap>Type:</th>
  <td><select name=datatype>
      [ad_generic_optionlist {number string} {number string}]
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
  <td><input name=default_value size=50></td>
</tr>

<tr><th colspan=2><input type=submit value=\"Add Parameter\"></th>
</tr>
</table>
</blockquote>
</form>
[ad_footer]
"



