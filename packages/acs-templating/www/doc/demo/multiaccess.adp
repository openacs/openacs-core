<html>
<head>
<title>Demo: Users</title>
</head>
<body>
<h1>Sample Users</h1>

  <if @users:rowcount;literal@ eq 0>
    <p>Sorry, there are no users in the system at this time.</p>
  </if>
    
  <table>
  <tr><th>First Name</th><th>Last Name</th><th>Full Name</th></tr>
  <multiple name=users>
  <if @users.rownum@ odd><tr></if><else><tr bgcolor="#eeeeee"></else>
    <td>@users.first_name@</td><td>@users.last_name@</td>
    <td>@users.full_name@</td>
  </tr>
  </multiple>
  </table>

  <br>
  <p>
  Results of data access:
  <ul>
    <li>The size of the datasource was: @size@</li>
    <li>The very last last name on the list was: @very_last_name@</li>
    <li>The very last first name on the list was: @last_first_name@</li>
  </ul>
  </p>

  </body>
</html>

