<master>
<property name="context">@context;noquote@</property>
<property name="title">Add group type</property>
				   
<if primary_rels:rowcount eq 0> 

<form method=post action=add-2>
@export_form_vars@

Select relation type:

<select name="rel_type">
  <option value=""> -- Please select --

<multiple name="primary_rels">
  <option value="@primary_rels.rel_type@"> @primary_rels.pretty_name@
</multiple>
</select>

<center>
<input type=submit>
</center>

</form>

</if>

<ul>
  <li> <a href=new?@export_url_vars@>Create your own relation type</a>
</ul>