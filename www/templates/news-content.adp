<master>
<property name="title">@pa.title@</property>
<property name="context_bar">@pa.context_bar;noquote@</property>

<if @pa.subtitle@ not nil>
<blockquote><b>@pa.subtitle@</b></blockquote>
</if>
<else>
<p>
</else>

<b>

<if @pa.location@ not nil>
@pa.location@ - 
</if>

@pa.release_date@ - 

</b>

@pa.content@

<p>
