<master src="../box-master-full">
<property name="title"><a href="/register/">Login / Register</a></property>

<table bgcolor="#006699" border="0" cellpadding="0" cellspacing="0" width="100%">
  <tr>
<form method="post" action="/register/user-login">
    <td>
  @export_vars@
  email<br>
  <input type="text" name="email"><br>
  password<br>
  <input type="password" name="password"><br>
  <input type="checkbox" name="persistent_cookie_p" value="1" CHECKED>
  <a href="/register/explain-persistent-cookies">Save password?</a>
  <input type="submit" value="login">
    </td>
</form>
  </tr>
</table>