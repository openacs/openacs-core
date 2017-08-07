<html>
<head>
<title>Demo: Templates</title>
</head>
  <body>
    <h1>Food</h1>
    <table>
      <list name=body>
        <tr>
          <td>(@body:rownum@)</td>
          <td bgcolor="#cc99ff">@body:item@</td>
        </tr>
      </list>
    </table>
  </body>
</html>
