<master>
<property name="title">Application error</property>

<if @custom_message@ nil>
We had a problem processing your entry.
</if>
<else>
@custom_message@
</else>
