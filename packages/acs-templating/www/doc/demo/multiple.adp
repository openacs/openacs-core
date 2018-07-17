<html>
<head>
<title>Demo: Sample Users</title>
</head>
<body>
<h1>Sample Users</h1>
  <if @users:rowcount;literal@ eq 0>
    <p>Sorry, there are no users in the system at this time.</p>
  </if>
  <else>
  <h2>Striped</h2>

  <blockquote>


  <table>
  <tr><th>First Name</th><th>Last Name</th></tr>
  <multiple name=users>
  <if @users.rownum@ odd><tr></if><else><tr bgcolor="#eeeeee"></else>
    <td>@users.first_name@</td><td>@users.last_name@</td>
  </tr>
  </multiple>
  </table>
  </blockquote>

  <h2>Maximally 2 rows, starting after 1</h2>

  <blockquote>
  <table>
  <tr><th>Row Number</th><th>First Name</th><th>Last Name</th></tr>
  <multiple name="users" maxrows="2" startrow="1">
    <tr><td>@users.rownum@</td>
        <td>@users.first_name@</td>
        <td>@users.last_name@</td></tr>
  </multiple>
  </table>
  </blockquote>
  </else>
  </body>
</html>
