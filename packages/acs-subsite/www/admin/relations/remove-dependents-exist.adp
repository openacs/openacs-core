<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Dependent relations exist</property>

You must remove the following dependent relations before you can
remove the @rel.rel_type_pretty_name@ between @rel.object_id_one_name@
and @rel.object_id_two_name@.

<p>

<ul>
  <multiple name="dependents">
    <li> @dependents.rel_type_pretty_name@ between 
         @dependents.object_id_one_name@ and @dependents.object_id_two_name@
         (<a href="remove?@dependents.export_vars@">remove</a>)
    </li>
  </multiple>
</ul>
