<html>
<head>
<title>Demo: Payment</title>
  <style>
    h1 { font-family: Arial, Helvetica }
    th { font-family: Arial, Helvetica }
    td { font-family: Arial, Helvetica }
  </style>
  </head>
  <body bgcolor="#FFFFCC">
  <h1>Make a Payment</h1>
<hr>

<p>Are you sure you want to proceed?</p>

<form action="pay" method="post">
@confirm_data;noquote@
<input type="submit" value="Confirm Payment">
</form>

<hr>
</body>
</html>
