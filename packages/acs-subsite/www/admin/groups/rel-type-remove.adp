<master>
<property name="context">@context;noquote@</property>
<property name="title">Remove @rel_pretty_name;noquote@</property>

Are you sure you want to remove @rel_pretty_name@ from the list of
allowable relations for the group @group_name@? Doing so will permanently:

<ul>

  <li> Remove all the elements related to this group through this relationship type
  <li> Remove all relational segments for this relationship type
  <li> Remove any constraints that relied on a relational segment defined by this group and relationship type

</ul>

<p>

<center>
<include src="../confirm-delete-form" action="rel-type-remove-2" export_vars="@export_vars;noquote@" no_button="No, I want to cancel my request" yes_button="Yes, I really want to delete this relationship type">
</center>
