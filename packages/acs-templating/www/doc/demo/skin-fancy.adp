<html>
<head>
<title>Demo: Skin</title>
  <style>
    h1 { font-family: Arial, Helvetica }
    th { font-family: Arial, Helvetica }
    td { font-family: Arial, Helvetica }
  </style>
</head>
<body bgcolor="#FFFFCC">
<h1>Sample Users</h1>
  <table cellpadding="4" cellspacing="0" border="1" bgcolor="#CCFFCC">
  <tr bgcolor="#eeeeee"><th>First Name</th><th>Last Name</th></tr>
  <multiple name=users>
  <tr>
    <td>@users.first_name@</td><td>@users.last_name@</td>
  </tr>
  </multiple>
  </table>
  </body>
</html>

