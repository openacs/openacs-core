<master>
<property name="context">@context;noquote@</property>
<property name="title">Add attribute to @object_pretty_name;noquote@</property>
<property name="focus">main_form.pretty_name</property>

<form method="post" name="main_form" action="add-2">
@export_vars;noquote@

<table>

 <tr>
  <td>Attribute pretty name:</td>
  <td><input type="text" name="pretty_name" maxlength=100></td>
 </tr>

 <tr>
  <td>Attribute pretty plural:</td>
  <td><input type="text" name="pretty_plural" maxlength=100></td>
 </tr>

 <tr>
  <td>Default value:</td>
  <td><input type="text" name="default_value" maxlength=100></td>
 </tr>

 <tr>
  <td>Required?:</td>
  <td><select name="required_p">
        <option value="f"> No, this attribute is not required
        <option value="t"> Yes, this attribute is required
      </select>
 </tr>

 <tr>
  <td>Datatype:</td>
  <td><select name="datatype">
        <option value=""> -- Please select --
      <multiple name="datatypes">
        <option value="@datatypes.datatype@"> @datatypes.datatype@
      </multiple>
      </select>
  </td>
 </tr>
</table>

<p>

<center>
<input type=submit>
</center>

</form>
