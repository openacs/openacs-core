<master src=fibo-master>
<property name=level>@n@</property>

<if @n@ ge 2>
  <td><include src=fibo n=@one_less@></td>
  <td><include src=fibo n=@two_less@></td>
</if><else>
  <td>*</td>
</else>
