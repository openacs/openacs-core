<master>
<property name="context">@context;noquote@</property>
<property name="title">Violations exists</property>

The following relations are in violation of the constraint you are
adding. You must remove these relations before you can add the
constraint:

<ul>
<multiple name="violations">
  <li> @violations.name@ (<a href=../../relations/remove?rel_id=@violations.rel_id@&return_url=@return_url_enc@>remove</a>) </li>
</multiple>
</ul>
