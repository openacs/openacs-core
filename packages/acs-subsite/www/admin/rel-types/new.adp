<master>
<property name="context">@context;noquote@</property>
<property name="title">Create relation type</property>

First, select the supertype for the new relationship type:

<form method=get action=new-2>
@export_vars;noquote@

Supertype: <select name=supertype>
<multiple name="supertypes">
  <option value="@supertypes.object_type@"> @supertypes.name;noquote@
</multiple>
</select>

<p>
<center><input type=submit value="Continue"></center>

</form>

