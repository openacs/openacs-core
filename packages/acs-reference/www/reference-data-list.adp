<master>
<property name="context">@context_bar;noquote@</property>
<property name="title">@title;noquote@</property>

<if @data:rowcount@ eq 0>
<i>You have no reference data in the database right now.</i><p>
</if>

<else>
    <ul>
    <multiple name=data>
    <li><a href="view-one-reference?repository_id=@data.repository_id@">@data.table_name@</a></li>
    </multiple>
    </ul>
</else>    





