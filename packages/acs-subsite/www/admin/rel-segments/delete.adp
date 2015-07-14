<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Remove segment</property>

Are you sure you want to remove the relational segment @segment_name@?
Removing this segment will also remove all relational constraints that
required elements to be in this segment.

<p>

<center>
<include src="../confirm-delete-form" action="delete-2" export_vars="@export_vars;literal@" no_button="No, I want to cancel my request" yes_button="Yes, I really want to delete this segment">
</center>



