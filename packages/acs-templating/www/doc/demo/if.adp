<html>
  <body>
    <h1>Conditional Expressions</h1>

    <p>The value of x is <b>@x@</b><br>
    The value of y is <b>@y@</b><br>
    The value of n is <b>@n@</b><br>
    The value of bool_t_p is <b>@bool_t_p@</b><br>
    The value of bool_1_p is <b>@bool_1_p@</b><br>
    The value of bool_f_p is <b>@bool_f_p@</b><br>
    The value of bool_0_p is <b>@bool_0_p@</b><p>

<table cellpadding=2 cellspacing=0 border=1>
<tr bgcolor=#eeeeee>
<th>Operator</th>
<th>Test</th>
<th>Result</th>
</tr>

<tr><td><tt><b>eq</b></tt></td>
    <td><tt>if \@x\@ eq 5</tt></td>
    <td><b><if @x@ eq 5>X is 5</if><else>X is not 5</else></b></td>
</tr>

<tr><td><tt><b>eq</b></tt></td>
    <td><tt>if \@x\@ eq 6</tt></td>
    <td><b><if @x@ eq 6>X is 6</if><else>X is not 6</else></b></td>
</tr>

<tr><td><tt><b>eq</b></tt></td>
    <td><tt>if \@n\@ eq "Fred's Flute"</tt></td>
    <td><b><if @n@ eq "Fred's Flute">N is "Fred's Flute"</if>
           <else>N is not "Fred's Flute"</else></b></td>
</tr>

<tr><td><tt><b>eq</b></tt></td>
    <td><tt>if \@n\@ eq "Fred"</tt></td>
    <td><b><if @n@ eq "Fred">N is "Fred"</if>
           <else>N is not "Fred"</else></b></td>
</tr>

<tr><td><tt><b>defined</b></tt></td>
    <td><tt>if \@x\@ defined</tt></td>
    <td><b><if @x@ defined>x is defined</if>
           <else>x is undefined</else></b></td>
</tr>

<tr><td><tt><b>nil</b></tt></td>
    <td><tt>if \@x\@ nil</tt></td>
    <td><b><if @x@ nil>x is nil</if>
           <else>x is nonnil</else></b></td>
</tr>

<tr><td><tt><b>defined</b></tt></td>
    <td><tt>if \@z\@ defined</tt></td>
    <td><b><if @z@ defined>z is defined</if>
           <else>z is undefined</else></b></td>
</tr>

<tr><td><tt><b>nil</b></tt></td>
    <td><tt>if \@z\@ nil</tt></td>
    <td><b><if @z@ nil>z is nil</if>
           <else>z is nonnil</else></b></td>
</tr>

<tr><td><tt><b>defined</b></tt></td>
    <td><tt>if \@w\@ defined</tt></td>
    <td><b><if @w@ defined>w is defined</if>
           <else>w is undefined</else></b></td>
</tr>

<tr><td><tt><b>nil</b></tt></td>
    <td><tt>if \@w\@ nil</tt></td>
    <td><b><if @w@ nil>w is nil</if>
           <else>w is nonnil</else></b></td>
</tr>

<tr><td><tt><b>nil</b></tt></td>
    <td><tt>if \@w\@ nil</tt></td>
    <td><b><if @w@ nil>w is nil</if>
           <else>w is nonnil</else></b></td>
</tr>

<tr><td><tt><b>true</b></tt></td>
    <td><tt>if \@bool_t_p\@ true</tt></td>
    <td><b><if @bool_t_p@ true>ok</if>
           <else>not ok</else></b></td>
</tr>

<tr><td><tt><b>true</b></tt></td>
    <td><tt>if \@bool_1_p\@ true</tt></td>
    <td><b><if @bool_1_p@ true>ok</if>
           <else>not ok</else></b></td>
</tr>

<tr><td><tt><b>true short</b></tt></td>
    <td><tt>if \@bool_t_p\@</tt></td>
    <td><b><if @bool_t_p@>ok</if>
           <else>not ok</else></b></td>
</tr>

<tr><td><tt><b>true short</b></tt></td>
    <td><tt>if \@bool_1_p\@</tt></td>
    <td><b><if @bool_1_p@>ok</if>
           <else>not ok</else></b></td>
</tr>


<tr><td><tt><b>false</b></tt></td>
    <td><tt>if \@bool_f_p\@ false</tt></td>
    <td><b><if @bool_f_p@ false>ok</if>
           <else>not ok</else></b></td>
</tr>

<tr><td><tt><b>false</b></tt></td>
    <td><tt>if \@bool_0_p\@ false</tt></td>
    <td><b><if @bool_0_p@ false>ok</if>
           <else>not ok</else></b></td>
</tr>

</table>

</body>
</html>
