<master>
<property name="context">@context@</property>
<property name="title">Delete @rel_type_pretty_name@</property>

Are you sure you want to delete this relationship type? Doing so will:

<ul>

  <li> Remove all relational segments that use this relationship type 
       (number of segments defined: @counts.segments@)
  </li>

  <li> Remove all the relations of this type 
       (number of relations defined: @counts.rels@)
  </li>

  <li> Remove this relationship type
  </li>

</ul>

<p>

<center>
<include src="../confirm-delete-form" action="delete-2" export_vars="@export_vars@" no_button="No, I want to cancel my request" yes_button="Yes, I really want to delete this relationship type">
</center>
