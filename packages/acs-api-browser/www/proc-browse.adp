<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

@dimensional_slider;noquote@

<if @sort_by@ eq "file">
  <% set last_file ""; set count 0 %>
  <multiple name="proc_list">
  <% if { $proc_list(file) != $last_file } { %>
    <% if {[incr count] >1} { %> </ul> <% } %>
    <strong>@proc_list.file@</strong> <ul>
    <% set last_file @proc_list.file@ %>
  <% } %>
  <li><a href="@proc_list.url@">@proc_list.proc@</a>
  </multiple>
  </ul>
</if>
<else>
  <ul>
  <multiple name="proc_list">
  <li><a href="@proc_list.url@">@proc_list.proc@</a> (defined in @proc_list.file@)
  </multiple>
  </ul>
</else>

<if @proc_list:rowcount@ eq 0>
Sorry, no procedures found
</if>
<else>
@proc_list:rowcount@ Procedures Found
</else>
