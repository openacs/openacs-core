ad_page_contract {

    Index of all object types (alphabetical, not hierarchichal)

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date August 15, 2000
    @cvs-id $Id$

} {}

set title "Alphabetical Index"

set page "
[ad_admin_header $title]
<h2>$title</h2>
[ad_context_bar [list "./index" "Object Type Administration"] $title]
<hr>
<ul>"

set body ""
db_foreach object_type_in_alphabetical_order {
    select object_type,
           pretty_name
      from acs_object_types
     order by lower(pretty_name)
} {

    append body "\n    <a href=\"./one?[export_url_vars object_type]\">$pretty_name</a><br>"

}

append page "
 <table border=0 cellspacing=0 cellpadding=0 width=90%>
  <tr>
   <td valign=top>$body
   </td>
   <td valign=top align=right><a href=\"./index\">Hierarchical Index</a></td>
  </tr>
 </table>"

append page "
</ul>
[ad_admin_footer]"

ns_return 200 text/html $page