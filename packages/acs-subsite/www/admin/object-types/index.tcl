ad_page_contract {

    Home page for OpenACS Object Type administration

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date August 13, 2000
    @cvs-id $Id$

} {}

set title "OpenACS Object Type Administration"

set page "
[ad_admin_header $title]
<h2>$title</h2>
[ad_context_bar $title]
<hr>
<ul>"

append page "
 <table border=0 cellspacing=0 cellpadding=0 width=90%>
  <tr>
   <td valign=top>[acs_object_type_hierarchy]
   </td>
   <td valign=top align=right><a href=\"./alphabetical-index\">Alphabetical Index</a></td>
  </tr>
 </table>"

append page "
</ul>
[ad_admin_footer]"

ns_return 200 text/html $page
