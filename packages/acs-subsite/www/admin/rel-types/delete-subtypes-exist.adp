<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Subtypes exist!</property>

You must remove all subtypes of the relationship type
"@rel_type_pretty_name@" before you can remove the group type.

<p>

The following subtypes currently exist:

<ul>
  <multiple name="subtypes">
    <li> @subtypes.pretty_name@ (<a href="delete?@subtypes.export_vars@">delete</a>)
  </multiple>
</ul>

