<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Delete @attribute_pretty_name;noquote@</property>

Are you sure you want to permanently remove this attribute? Doing so will also remove any values previously specified for this attribute for any object of type "@object_type@."


<p>

<center>
<include src="../confirm-delete-form" action="delete-2" export_vars="@export_form_vars;literal@" no_button="No, I want to cancel my request" yes_button="Yes, I really want to delete this attribute">
</center>
