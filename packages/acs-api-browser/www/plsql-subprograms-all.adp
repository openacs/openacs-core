<master>
<property name=title>All PL/SQL Subprograms</property>
<property name="context">@context;noquote@</property>

<multiple name="all_subprograms">
<h2>@all_subprograms.type@</h2>

<ul>
<group column="type">
<li><a href="plsql-subprogram-one?type=<%= [ns_urlencode @all_subprograms.type@] %>&name=<%= [ns_urlencode @all_subprograms.name@] %>"><code><%= [string tolower @all_subprograms.name@] %></code></a></li>
</group>
</ul>

</multiple>

