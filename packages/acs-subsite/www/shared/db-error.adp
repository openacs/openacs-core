<master>
<property name="title">Database Error</property>
<property name="context">Database Error</property>

<p><if @custom_message@ nil>
We had a problem processing your entry.
</if>
<else>
@custom_message@
</else>
</p>
<p>Here's what the database reported:
<blockquote>
@errmsg@
</blockquote>
</p>
