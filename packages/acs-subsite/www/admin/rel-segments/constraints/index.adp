<master>
<property name="context">@context;noquote@</property>
<property name="title">Relational Constraint Administration</property>

Currently, the system is able to handle the following relational constraints:

<ul>

  <if @constraints:rowcount@ eq 0>
    <li>(none)</li>
  </if>
  <else>
    <multiple name="constraints">
      <li> <a href="one?constraint_id=@constraints.constraint_id@">@constraints.constraint_name@</a> </li>
    </multiple>
  </else>

</ul>

Note: Relational constraints are created from the <a href=../>relational segment administration pages</a>
