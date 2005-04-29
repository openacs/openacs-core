<master>
 <property name="title">Import messages from Translation Server</property>

Import results for
<if @single_package_p@ eq 0>
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
  Import finished. Number of messages processed: @message_count_total.processed@, added: @message_count_total.added@, updated: @message_count_total.updated@, 
  deleted: @message_count_total.deleted@.
</p>

<if @errors_list@ not nil>
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

<ul class="action-links">
  <li><a href="@return_url@">Return</a></li>
</ul>
