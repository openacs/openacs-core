<master>
<property name="context">@context@</property>
<property name="title">Delete @constraint_name@</property>

Are you sure you want to delete the constraint @constraint_name@ on segment @segment_name@?


<p>

<center>
<include src="../../confirm-delete-form" action="delete-2" export_vars="@export_vars@" no_button="No, I want to cancel my request" yes_button="Yes, I really want to delete this constraint">
</center>
