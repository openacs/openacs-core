<html>
<head>
<title>Demo: Grid</title>
  <style>
    h1 { font-family: Arial, Helvetica }
    th { font-family: Arial, Helvetica }
    td { font-family: Arial, Helvetica }
  </style>
  </head>
  <body bgcolor="#FFFFCC">
  <h1>Sample Users</h1>
  <table cellpadding="8" cellspacing="0" border="1" bgcolor="#CCFFCC">

<grid name="users" cols="3">

  <if @users.col@ eq "1">
    <!-- Begin row -->
    <tr>
  </if>

  <!-- Cell layout -->
  <td>

    <!-- Cells may be unoccupied at the end. -->
    <if @users.rownum@ le @users:rowcount@>
      @users.rownum@.
      @users.first_name@
      @users.last_name@
    </if>

    <else>
      <!-- Placeholder to retain cell formatting -->
      &nbsp;
    </else>

  </td>
  <!-- End cell layout -->

  <if @users.col@ eq "3">
    <!-- End row -->
    </tr>
  </if>

</grid>

</table>
</body>
</html>
