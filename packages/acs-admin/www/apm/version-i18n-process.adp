<master>
<property name="title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>

<p>
  <b>Current File:</b> @file@
</p>

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

<h3>Instructions</h3>

<p>
  Choose which message keys to use for this file. If you leave a
  message key blank no replacement will be done and the corresponding
  text in the adp will be left untouched. The text that is actually
  replaced is bold and highlighted with a yellow background in the
  "Text to Replace" column.
</p>

