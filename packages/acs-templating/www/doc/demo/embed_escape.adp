<html>
  <body>
    <h1>Welcome</h1>

    <p>
      <% if { $x == 5 } { %>
        Yes, <b>x</b> is indeed 5.
      <% } else { %>
        No, <b>x</b> is not 5.
      <% } %>
    </p>

    <table>
    <% foreach creature [list giraffe lion antelope fly] { %>
    
      <% if [regexp {a} $creature] { %> 
        <tr bgcolor=#eeeeee>
      <% } else { %>
        <tr>
      <% } %>

      <td><%=$creature%></td>
      </tr>
    <% } %>
    </table>

  </body>
</html>
