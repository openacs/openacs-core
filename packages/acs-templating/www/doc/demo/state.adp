<html>
  <head>
  <style>
    h1 { font-family: Arial, Helvetica }
    th { font-family: Arial, Helvetica }
    td { font-family: Arial, Helvetica }
  </style>
  </head>
  <body bgcolor="#FFFFCC">
<h1>Sample Users by State</h1>

<if @requesterror.state_abbrev@ not nil>
  <p>Sorry, there was an error processing your request:<br>
     <b>@requesterror.state_abbrev@</b>
  </p>
</if>

<else>

<table cellpadding=4 cellspacing=0 border=1 bgcolor=#CCFFCC>

<tr bgcolor=#eeeeee><td>@state_abbrev@</td></tr> 

<multiple name="users">

  <tr bgcolor=#ffffff><td>
        <p>The @users.last_name@ Family</p>
          <ul>   
            <group column="last_name"> 
              <li>@users.first_name@ @users.last_name@</li> 
            </group>
          </ul>
  </td></tr>

</multiple>

</table>

</else>

