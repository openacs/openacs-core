<html>
<head>
<title>Demo: Inner olar System</title>
</head>
<body>
<h1>The Inner Solar System</h1>
  <table>
  <tr><th>#</th>
  <th>Name</th><th>Diameter</th><th>Mass</th><th>Orbit Radius</th></tr>
  <tr><th></th><th></th><th>[km]</th><th>[kg]</th><th>[km]</th></tr>
  <multiple name=body>
  <tr>
	  <td>@body.rownum@</td>
	  <td>@body.name@</td>
	  <td align="right">@body.diameter@</td>
	  <td align="right">@body.mass@</td>
	  <td align="right">@body.r_orbit@</td>
  </tr>
  </multiple>
  </table>
  </body>
</html>
