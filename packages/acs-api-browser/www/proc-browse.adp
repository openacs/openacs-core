<master>
<property name="title">@title;noquote@</property>
<property name="context">@context;noquote@</property>

@dimensional_slider;noquote@

<ul>
<if @sort_by@ eq "file">
  <% set last_file "" %>
  <multiple name="proc_list">
  <% if { $proc_list(file) != $last_file } { %>
    </ul><b>@proc_list.file@</b> <ul>
    <% set last_file @proc_list.file@ %>
  <% } %>
  <li><a href="@proc_list.url@">@proc_list.proc@</a>
  </multiple>
</if>
<else>
  <multiple name="proc_list">
  <li><a href="@proc_list.url@">@proc_list.proc@</a> (defined in @proc_list.file@)
  </multiple>
</else>
</ul>

<if @proc_list:rowcount@ eq 0>
Sorry, no procedures found
</if>
<else>
@proc_list:rowcount@ Procedures Found
</else>
