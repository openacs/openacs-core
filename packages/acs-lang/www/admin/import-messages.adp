<master>
 <property name="title">@page_title;noquote@</property>

Import results for
<if @package_key@ nil>
  <b>all packages</b>
</if>
<else>
package <b>@package_key@</b>
</else>
and
<if @locale@ nil>
  <b>all locales</b>
</if>
<else>
locale <b>@locale@</b>
</else>.

<p>
  Import finished. Number of messages processed: @message_count.processed@, added: @message_count.added@, updated: @message_count.updated@, 
  deleted: @message_count.deleted@.
</p>

<if @conflict_count@ gt 0>
  <font color="red">There are @conflict_count@ message conflicts in the database.</font> 

<p>
  <b>&raquo;</b> <a href="@conflict_url@">Proceed to resolve conflicts</a>
</p>
</if>
<else>
  There are currently no conflicts in the database.
</else>

<p>
  <b>&raquo;</b> <a href="@return_url@">Return</a>
</p>
