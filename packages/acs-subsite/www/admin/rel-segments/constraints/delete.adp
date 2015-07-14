<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Delete @constraint_name;noquote@</property>

Are you sure you want to delete the constraint @constraint_name@ on segment @segment_name@?


<p>

<center>
<include src="../../confirm-delete-form" action="delete-2" export_vars="@export_vars;literal@" no_button="No, I want to cancel my request" yes_button="Yes, I really want to delete this constraint">
</center>
