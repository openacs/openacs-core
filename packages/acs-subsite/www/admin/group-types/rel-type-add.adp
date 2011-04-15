<master>
<property name="context">@context;noquote@</property>
<property name="doc(title)">@doc.title@</property>
				  

<h1>#acs-subsite.Add_relationship_for_group__group_type#</h1>

<if @primary_rels:rowcount@ eq "0">
  <p>There are no other relationship types that you can add. You can <a href=../rel-types/new?return_url=@return_url_enc@>create a new relationship type</a> if you like.</p>
</if>
<else>
<form method="get" action="rel-type-add-2">
<div>@export_vars;noquote@</div>

<div>
  <label for="rel_type">#acs-subsite.Select_relation_type#

  <select name="rel_type" id="rel_type">
  <option value="" selected> #acs-subsite.Please_select#</option>
  <multiple name="primary_rels">
    <option value="@primary_rels.rel_type@"> @primary_rels.indent;noquote@ @primary_rels.pretty_name@</option>
  </multiple>
  </select>
  </label>
  <input type="submit" value="OK">
</div>

</form>

<p>
  <a href="../rel-types/new?return_url=@return_url_enc@" class="button">#acs-subsite.create_a_new_relationship_type#</a>
</p>

</else>

