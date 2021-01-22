<html>
<head><title>Demo: Explicit Escape</title>
</head>
<body>
<h1>Sample Users</h1>
  <table>
  <tr><th>First Name</th><th>Last Name</th></tr>
  <multiple name=users>
  <tr>
    <td>@users.first_name@</td><td>@users.last_name@</td>
  </tr>
  </multiple>
  </table>
  </body>
</html>

