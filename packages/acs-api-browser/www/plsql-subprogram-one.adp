<%= [ad_header $name] %>

<h2>@name@</h2>

<%= [ad_context_bar {"" "API Browser"} {"plsql-subprograms-all" "All PL/SQL Subprograms"} "One PL/SQL Subprogram"] %>

<hr>

<if @package_slider_list@ ne "">
<table align=right><tr><td>
[ <%= [join $package_slider_list " | "] %> ]
</td></tr></table>
</if>

<blockquote>
<pre>
@source_text@
</pre>
</blockquote>

<%= [ad_footer] %>

