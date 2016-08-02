<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

Sorry, no <%= [ns_info name]%> Tcl API procedures were found with that name.

<p>

You can try searching the <a href="@doc_url;noi18n@"><%= [ns_info name]%> documentation</a> yourself.

<p>

<div style="background: #dddddd; display: inline-block; padding: 5px;">
     <form action="tcl-proc-view" method="get">
     <div><strong>Tcl Api Search:</strong><br>
     <input type="text" name="tcl_proc" value="@tcl_proc@">
     <!-- <if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if> -->
     <input type="submit" value="Go"><br>
     </div>
     </form>
</div>