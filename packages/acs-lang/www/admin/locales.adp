<p>List of Locales</p>
<table cellpadding="0" cellspacing="0" border="0">
 <tr>
  <td style="background: #CCCCCC">
   <table cellpadding="4" cellspacing="1" border="0">
    <tr style="background: #FFFFe4">
     <th>Locale</th>
     <th>Label</th>
     <th>Default</th>
     <th>Action</th>
    </tr>
    <multiple name="locales">
     <tr style="background: #EEEEEE">
      <td>@locales.locale@</td>
      <td>@locales.locale_label@</td>
      <td>
       <if @locales.default_p@ eq "t">Yes</if>
       <else>No (<a href="locale-make-default?locales=@locales.escaped_locale@"><span class="small">make default</span></a>)</else>
      </td>
      <td>(<a href="locale-edit?locales=@locales.escaped_locale@">edit</a>)&nbsp;
          (<a href="locale-delete?locales=@locales.escaped_locale@">delete</a>)
      </td>
     </tr>
    </multiple>
   </table>
  </td>
 </tr>
</table>
<p>(<a href="locale-new">Create New Locale</a>)</p>
