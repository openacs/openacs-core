<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>

Choose which message keys to use for file @adp_file@. If you leave a message key blank no replacement will be done
and the corresponding text in the adp will be left untouched. The text that is actually replaced is bold and highlighted
with a yellow background in the "Text to Replace" column.

<blockquote>

<form action="version-i18n-process-2">
  @hidden_form_vars@

  <table  border="1">
    <tr>
      <th>Text to Replace</th>
      <th>Message key to use</th>
    </tr>

  <multiple name="replacements">
    <tr>
      <td>@replacements.text@</td>
      <td><input type="text" name="message_keys" value="@replacements.key@" /></td>
    </tr>
  </multiple>    
  </table>

  <p>
  <input type="submit" value="Process ADP" />
  </p>
</form>

</blockquote>
