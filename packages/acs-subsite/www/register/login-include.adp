
<form method="post" action="/register/user-login" name="login">
@export_vars@

<table>
  <tr>
    <td>Your email address:</td>
    <td><input type="text" name="email" value="@email@" /></td>
  </tr>

  <tr>
    <td>Your password:</td>
    <td><input type="password" name="password" /></td>
  </tr>

  <if @allow_persistent_login_p@ eq 1>
    <tr>
      <td colspan="2">
        <if @persistent_login_p@ eq 1>
          <input type="checkbox" name="persistent_cookie_p" value="1" checked="checked" id="persistent"/> 
        </if>
        <else>
          <input type="checkbox" name="persistent_cookie_p" value="1" id="persistent"/> 
        </else>
        <label for="persistent">Remember this address and password?</label>
        (<a href="explain-persistent-cookies">help</a>)
      </td>
    </tr>
  </if>

  <tr>
    <td colspan="2" align="center">
      <input type="submit" value="Submit" />
    </td>
  </tr>

  <tr>
    <td colspan="2" align="center">
      Have you <a href="/register/email-for-password">forgotten your password?</a>
    </td>
  </tr>

</table>

</form>

