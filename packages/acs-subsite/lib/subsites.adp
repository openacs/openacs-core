<if @subsites:rowcount@ gt 0>
  <p><listtemplate name="subsites"></listtemplate></p>
</if>
<else>
  <p> There are no @pretty_plural@ here. </p>
</else>

<if @add_url@ not nil>
  <p> <b>&raquo;</b> <a href="@add_url@">Create new @pretty_name@</a> </p>
</if>
