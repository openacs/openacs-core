<html>
<head>
<title>Recursive include</title>
</head>
  <body>
    <h2>
      Testcase for recursive <code>include</code> and <code>if</code>
    </h2>
    <p>
      This pages does two things:
    </p>
    <ol>
      <li>It exercises <code>include</code> recursively, passing
	changing args.
      <li>The result is the test case for <code>if</code> and
	<code>else</code>,  nesting them deeply and exercising all
	predicates, with and without "not"
    </ol>

    <p>
     @lt@multiple name=v>
<include src=include indent="@indent;noquote@      " l="
      {%x% FALSE nil}
      {%y% TRUE nil}
      {%z% TRUE nil}
      {%x% TRUE defined}
      {%y% TRUE defined}
      {%z% FALSE defined}
      {%x% FALSE lt 3}
      {@quot;noquote@yes@quot;noquote@ TRUE true}
      {0 FALSE true}
      {t FALSE false}
      {oFf TRUE false}
      {%x% TRUE true}
      {%x% TRUE gt %v.five%}
      {%x% FALSE ge 20}
      {%x% TRUE le 13}
      {%v.five% TRUE eq 5}
      {%x% FALSE eq 5}
      {%x% FALSE odd}
      {%x% TRUE even}
      {%v.rownum% TRUE odd}
      {%v.five% FALSE even}
      {%x% FALSE in fo {ob 10} ar}
      {%x% TRUE in fie 6 10 28}
      {%v.five% TRUE between 3 30}
      {%v.five% FALSE between 30 300}
      {%x% TRUE ne %v.five% and 8 FALSE le %v.five% and %x% TRUE defined}
      {%x% TRUE ne 10 or 6 FALSE eq %v.five%}">
     @lt@/multiple>
    </p>
  </body>
</html>
