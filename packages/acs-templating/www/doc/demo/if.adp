<html>
<head>
<title>Demo: Conditional Expressions</title>
</head>
  <body>
    <h1>Conditional Expressions</h1>

    <p>The value of x is <strong>@x@</strong><br>
    The value of y is <strong>@y@</strong><br>
    The value of n is <strong>@n@</strong><br>
    The value of bool_t_p is <strong>@bool_t_p@</strong><br>
    The value of bool_1_p is <strong>@bool_1_p@</strong><br>
    The value of bool_f_p is <strong>@bool_f_p@</strong><br>
    The value of bool_0_p is <strong>@bool_0_p@</strong><p>

<table cellpadding="2" cellspacing="0" border="1">
<tr bgcolor="#eeeeee">
<th>Operator</th>
<th>Test</th>
<th>Result</th>
</tr>

<tr><td><kbd><strong>eq</strong></kbd></td>
    <td><kbd>if \@x\@ eq 5</kbd></td>
    <td><strong><if @x@ eq 5>X is 5</if><else>X is not 5</else></strong></td>
</tr>

<tr><td><kbd><strong>eq</strong></kbd></td>
    <td><kbd>if \@x\@ eq 6</kbd></td>
    <td><strong><if @x@ eq 6>X is 6</if><else>X is not 6</else></strong></td>
</tr>

<tr><td><kbd><strong>eq</strong></kbd></td>
    <td><kbd>if \@n\@ eq "Fred's Flute"</kbd></td>
    <td><strong><if @n@ eq "Fred's Flute">N is "Fred's Flute"</if>
           <else>N is not "Fred's Flute"</else></strong></td>
</tr>

<tr><td><kbd><strong>eq</strong></kbd></td>
    <td><kbd>if \@n\@ eq "Fred"</kbd></td>
    <td><strong><if @n@ eq "Fred">N is "Fred"</if>
           <else>N is not "Fred"</else></strong></td>
</tr>

<tr><td><kbd><strong>defined</strong></kbd></td>
    <td><kbd>if \@x\@ defined</kbd></td>
    <td><strong><if @x@ defined>x is defined</if>
           <else>x is undefined</else></strong></td>
</tr>

<tr><td><kbd><strong>nil</strong></kbd></td>
    <td><kbd>if \@x\@ nil</kbd></td>
    <td><strong><if @x@ nil>x is nil</if>
           <else>x is nonnil</else></strong></td>
</tr>

<tr><td><kbd><strong>defined</strong></kbd></td>
    <td><kbd>if \@z\@ defined</kbd></td>
    <td><strong><if @z@ defined>z is defined</if>
           <else>z is undefined</else></strong></td>
</tr>

<tr><td><kbd><strong>nil</strong></kbd></td>
    <td><kbd>if \@z\@ nil</kbd></td>
    <td><strong><if @z@ nil>z is nil</if>
           <else>z is nonnil</else></strong></td>
</tr>

<tr><td><kbd><strong>defined</strong></kbd></td>
    <td><kbd>if \@w\@ defined</kbd></td>
    <td><strong><if @w@ defined>w is defined</if>
           <else>w is undefined</else></strong></td>
</tr>

<tr><td><kbd><strong>nil</strong></kbd></td>
    <td><kbd>if \@w\@ nil</kbd></td>
    <td><strong><if @w@ nil>w is nil</if>
           <else>w is nonnil</else></strong></td>
</tr>

<tr><td><kbd><strong>nil</strong></kbd></td>
    <td><kbd>if \@w\@ nil</kbd></td>
    <td><strong><if @w@ nil>w is nil</if>
           <else>w is nonnil</else></strong></td>
</tr>

<tr><td><kbd><strong>true</strong></kbd></td>
    <td><kbd>if \@bool_t_p\@ true</kbd></td>
    <td><strong><if @bool_t_p;literal@ true>ok</if>
           <else>not ok</else></strong></td>
</tr>

<tr><td><kbd><strong>true</strong></kbd></td>
    <td><kbd>if \@bool_1_p\@ true</kbd></td>
    <td><strong><if @bool_1_p;literal@ true>ok</if>
           <else>not ok</else></strong></td>
</tr>

<tr><td><kbd><strong>true short</strong></kbd></td>
    <td><kbd>if \@bool_t_p\@</kbd></td>
    <td><strong><if @bool_t_p;literal@ true>ok</if>
           <else>not ok</else></strong></td>
</tr>

<tr><td><kbd><strong>true short</strong></kbd></td>
    <td><kbd>if \@bool_1_p\@</kbd></td>
    <td><strong><if @bool_1_p;literal@ true>ok</if>
           <else>not ok</else></strong></td>
</tr>


<tr><td><kbd><strong>false</strong></kbd></td>
    <td><kbd>if \@bool_f_p\@ false</kbd></td>
    <td><strong><if @bool_f_p;literal@ false>ok</if>
           <else>not ok</else></strong></td>
</tr>

<tr><td><kbd><strong>false</strong></kbd></td>
    <td><kbd>if \@bool_0_p\@ false</kbd></td>
    <td><strong><if @bool_0_p;literal@ false>ok</if>
           <else>not ok</else></strong></td>
</tr>

</table>

</body>
</html>
