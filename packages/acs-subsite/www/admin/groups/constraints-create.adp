<master>
<property name="context">@context;noquote@</property>
<property name="title">Constraints on relationship type</property>

Relational segments allows you to treat all parties that have a
@rel_type_pretty_name@ to @group_name@ as a party itself. This is
useful for assigning permissions and for further constraining which
parties can use the @rel_type_pretty_name@. 

<p>

Once you create a relational segment, you will be able to create
relational constraints on that segment. Relational constraints allow
you to apply rules on inter-party relationships

<p>

Would you like to create a relational segment and/or constraints now?

<p>

<center>
<include src="../confirm-delete-form" action="constraints-create-2" export_vars="@export_vars;noquote@" no_button=" No " yes_button=" Yes ">
</center>
