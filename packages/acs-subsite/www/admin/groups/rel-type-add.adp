<master>
<property name="context">@context;noquote@</property>
<property name="title">Add relation type</property>
				   
<if @primary_rels:rowcount@ eq "0">
  There are no other relationship types that you can add. You can
  <a href=../rel-types/new?return_url=@return_url_enc@>create a new relationship type</a> if you like.
</if>
<else>
<form method=get action=rel-type-add-2>
@export_vars;noquote@

Select relation type:

<select name="rel_type">
  <option value=""> -- Please select --
<multiple name="primary_rels">
  <option value="@primary_rels.rel_type@"> @primary_rels.indent;noquote@ @primary_rels.pretty_name@
</multiple>
</select>

<center>
<input type=submit>
</center>

</form>

<ul>

  <li> <a href=../rel-types/new?return_url=@return_url_enc@>create a new relationship type</a> </li>

</ul>

</else>
