<master>
<property name="title">Database error</property>

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