<master>
<property name="doc(title)">Problem with Your Input</property>

<hr>

We had
<if @n_errors@ eq 1>
  a problem
</if><else>
  some problems
</else>
 processing your entry:
        
<ul> 
  <list name=error_list>        
    <li>@error_list:item@
  </list>
</ul>
