<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Delete @group_name;noquote@</property>

Are you sure you want to permanently, and irreversibly, remove this
group? Removing this group will:

<ul>

  <li> Remove all elements of this group (of which there are currently
  @number.elements@)

  <li> Remove all segments defined for this group (of which there are
  currently @number.segments@)

  <li> Remove any relational constraints that require this group in
  any way (of which there are currently @number.constraints@)

</ul>

<p>

<div>
<include src="../confirm-delete-form" action="delete-2" export_vars="@export_form_vars;literal@" no_button="No, I want to cancel my request" yes_button="Yes, I really want to delete this group">
</div>
