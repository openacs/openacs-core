<master src=fibo-master>
<property name=level>@n;noquote@</property>

<if @n@ ge 2>
  <td><include src=fibo n="@one_less;literal@"></td>
  <td><include src=fibo n="@two_less;literal@"></td>
</if><else>
  <td>*</td>
</else>
