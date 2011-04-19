<master>
<property name="context">@context;noquote@</property>
<property name="doc(title)">#acs-subsite.Create_relation_type#</property>

<h1>#acs-subsite.Create_relation_type#</h1>

<p>#acs-subsite.First_select_the_supertype#</p>

<form method=get action=new-2>
<div>@export_vars;noquote@</div>

<div>
<label for="supertype">
  #acs-subsite.Supertype#
  <select name="supertype" id="supertype">
  <multiple name="supertypes">
    <option value="@supertypes.object_type@">@supertypes.name;noquote@</option>
  </multiple>
  </select>
</label>

<input type="submit" value="Continue">
</div>

</form>

