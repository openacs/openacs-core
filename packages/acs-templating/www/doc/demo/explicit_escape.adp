<html>
  <body>
    <h1>Hello</h1>

    <%
      foreach name [list Fred Ginger Mary Sarah Elmo] {
        template::adp_puts "<p>Welcome to this page $name!</p>"
      }
    %>

  </body>
</html>
