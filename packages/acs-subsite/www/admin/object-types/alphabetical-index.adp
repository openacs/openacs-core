<master>
  <property name="doc(title)">@doc.title;literal@</property>
  <property name="context">@context;literal@</property>

 <h1>@doc.title@</h1>

 <p><a href="index" class="button">View Hierarchical Index</a></p>

<ul>
  <multiple name="alpha_object_types">
    <li><a href="one?object_type=@alpha_object_types.object_type@">@alpha_object_types.pretty_name@</a></li>
  </multiple>
</ul>
