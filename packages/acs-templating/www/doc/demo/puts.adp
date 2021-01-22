<html>
<head>
<title>Demo: puts Examples</title>
</head>
<body>
    <h2>There&apos;s More than One Way to Do it</h2>

    <h3>ADP</h3>
    <if @x@ eq 4>
       x is four
    </if><else>
       x differs from four
    </else>

    <h3>Tcl</h3>
    You can call <code>adp_puts</code> from Tcl.
    <em>This procedure is undocumented, and its use is deprecated.</em>
    <p>
    <%
      if {$x == 4} {
	adp_puts "x is four"
      } {
        adp_puts "x differs from four"
      }
    %>

  </body>
</html>
