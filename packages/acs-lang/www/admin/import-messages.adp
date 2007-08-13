<master>
 <property name="title">@page_title;noquote@</property>
<br />
<if @confirm_url@ not nil>
  <p>Please confirm that you want to overwrite the message catalog and lose your local changes: <a href="@confirm_url@">Yes, that is what I want!</a></p>
  <p><br /></p>
  <p><a href="@return_url@">No, go back!</a></p>
</if>
<else>

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
<hr />
<br />
<p>
  Import finished. Number of messages processed: @message_count.processed@, added: @message_count.added@, updated: @message_count.updated@,
  deleted: @message_count.deleted@.
</p>

<if @message_count.errors@ not nil>
<p>
  The following errors were produced:

  @errors_list;noquote@
</p>
</if>

<if @conflict_count@ gt 0>
  <font color="red">There are @conflict_count@ message conflicts in the database.</font> 

  <ul class="action-links">
    <li><a href="@conflict_url@">Proceed to resolve conflicts</a></li>
  </ul>
</if>
<else>
  There are currently no conflicts in the database.
</else>
<p /><br />
<ul class="action-links">
  <li><a href="@return_url@">Return</a></li>
</ul>
</else>