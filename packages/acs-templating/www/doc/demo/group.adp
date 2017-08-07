<html>
<head>
<title>Demo: Sample Users</title>
  <style>
    h1 { font-family: Arial, Helvetica }
    th { font-family: Arial, Helvetica }
    td { font-family: Arial, Helvetica }
  </style>
</head>
<body bgcolor="#FFFFCC">
<h1>Sample Users by State</h1>
  <table cellpadding="4" cellspacing="0" border="1" bgcolor="#CCFFCC">

<multiple name="users">

  <tr bgcolor="#eeeeee"><td>@users.state@</td></tr> 
  <tr bgcolor="#ffffff"><td>
      <group column="state">
        <p>The @users.last_name@ Family</p>
          <ul>   
            <group column="last_name"> 
              <li>@users.first_name@ @users.last_name@</li> 
            </group>
          </ul>
      </group>
  </td></tr>

</multiple>

</table>