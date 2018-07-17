<master>
<property name="context">@context_bar;literal@</property>
<property name="doc(title)">@title;literal@</property>

<if @data:rowcount;literal@ eq 0>
<em>You have no reference data in the database right now.</em><p>
</if>

<else>
    <ul>
    <multiple name=data>
    <li><a href="view-one-reference?repository_id=@data.repository_id@">@data.table_name@</a></li>
    </multiple>
    </ul>
</else>    





