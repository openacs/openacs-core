<html>
<head>
<title>Demo: Passing Datasources</title>
</head>
<body>
<h1>Passing a Multirow Datasource</h1>

    Here are all sample users.

    <blockquote>
      <table border="1" bgcolor="#ccff99"><tr><td>
        <include src="reference-inc" &="users">
      </td></tr></table>
    </blockquote>

    The following have an "e" in their first names.

    <blockquote>
      <table border="1" bgcolor="#ffcc99"><tr><td>
        <include src="reference-inc" &users="e_people">
      </td></tr></table>
    </blockquote>

    This is the outer template again.
  </body>
</html>
