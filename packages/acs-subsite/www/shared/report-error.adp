<master>
<property name="title">Application Error</property>
<property name="context">Error</property>

<if @custom_message@ nil>
We had a problem processing your entry.
</if>
<else>
@custom_message@
</else>
