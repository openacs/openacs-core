              <td width="1%"><img src="/templates/slices/spacer.gif" width="5" height="1" border="0" alt=""></td>
              <td width="15%" NOWRAP><span class="user-status">

<if @login_p@ eq 1>
<a href="/register/logout">Log Out</a>
</if>
<else>
<a href="@register_url@">Log In</a>
</else>

</span></td>

              <td width="32%" NOWRAP><span class="user-status">

<if @login_p@ eq 1>
logged in as<br><a href="/pvt/home">@name@</a>
</if>
<else>
<a href="@register_url@">Register</a>
</else>

</span></td>

