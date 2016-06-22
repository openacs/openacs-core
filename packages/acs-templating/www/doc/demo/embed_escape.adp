<html>
<head>
<title>Demo: Embed Escape</title>
</head>
  <body>
    <h1>Welcome</h1>

    <p>
      <% if { $x == 5 } { %>
        Yes, <strong>x</strong> is indeed 5.
      <% } else { %>
        No, <strong>x</strong> is not 5.
      <% } %>
    </p>

    <table>
    <% foreach creature [list giraffe lion antelope fly] { %>
    
      <% if [regexp {a} $creature] { %> 
        <tr bgcolor="#eeeeee">
      <% } else { %>
        <tr>
      <% } %>

      <td><%=$creature%></td>
      </tr>
    <% } %>
    </table>

  </body>
</html>
