<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Relationship types exist that depend on this group type</property>

You must remove all of the following relationship types before you can
remove the @group_type_pretty_name@ group type.

<p>

The following relationship types currently depend on this group type:

<ul>
  <multiple name="rel_types">
    <li> @rel_types.pretty_name@ (<a href="../rel-types/delete?@rel_types.export_vars@">delete</a>)
  </multiple>
</ul>

