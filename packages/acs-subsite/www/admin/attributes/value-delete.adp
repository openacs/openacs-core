<master>
<property name="context">@context;noquote@</property>
<property name="title">Delete value @pretty_name;noquote@</property>

Are you sure you want to permanently remove this attribute value?

<p>

<center>
<include src="../confirm-delete-form" action="value-delete-2" export_vars="@export_vars;noquote@" no_button="No, I want to cancel my request" yes_button="Yes, I really want to delete this attribute value">
</center>
