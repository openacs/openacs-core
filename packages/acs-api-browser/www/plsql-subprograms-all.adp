<%= [ad_header "All PL/SQL Subprograms"] %>

<h2>All PL/SQL Subprograms</h2>

<%= [ad_context_bar {"" "API Browser"} "All PL/SQL Subprograms"] %>

<hr>

<multiple name="all_subprograms">
<h3>@all_subprograms.type@</h3>

<ul>
<group column="type">
<li><a href="plsql-subprogram-one?type=<%= [ns_urlencode @all_subprograms.type@] %>&name=<%= [ns_urlencode @all_subprograms.name@] %>"><code><%= [string tolower @all_subprograms.name@] %></code></a>
</group>
</ul>

</multiple>

<%= [ad_footer] %>
