<master>
<property name="title">Application error</property>
<h2>Database error</h2>
<if @custom_message@ nil>
We had a problem processing your entry.
</if>
<else>
@custom_message@
</else>
<p>Here's what the database reported:
<blockquote>
@errmsg@
</blockquote>
