<master>
<property name="context">@context;noquote@</property>
<property name="title">Delete @group_type_pretty_name;noquote@</property>

<ul>

  <li> Remove the "@group_type_pretty_name@" group type 

  <li> Remove all the groups of this type (of which there are
  currently @groups_of_this_type@), including any relational segments
  and constraints defined on those groups

  <li> Remove all the relations for groups of this type (of which
  there are currently @relations_to_this_type@) 

</ul>

<p>

<center>
<include src="../confirm-delete-form" action="delete-2" export_vars="@export_form_vars;noquote@" no_button="No, I want to cancel my request" yes_button="Yes, I really want to delete this group type">
</center>
