<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

Sorry, no Tcl procedures were found with that name.

<p>

You can try searching the <a href="@tcl_docs_url;noi18n@">Tcl documentation</a> yourself.

<p>

<table cellpadding="5">
  <tr>
    <td bgcolor="#dddddd">
     <form action="tcl-doc-search" method="get">
     <strong>Tcl Documentation Search:</strong><br>
     <input type="text" name="tcl_proc" value="@tcl_proc@">
     <if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if>
     <input type="submit" value="Go"><br>
     </form>
     </td>
  </tr>
</table>
