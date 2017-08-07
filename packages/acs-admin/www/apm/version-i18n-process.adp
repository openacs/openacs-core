<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context_bar">@context_bar;literal@</property>

<p>
  <strong>Current File:</strong> @file@
</p>

<blockquote>

<form action="version-i18n-process-2">
  @hidden_form_vars;noquote@
  <input type="hidden" name="number_of_keys" value="@replacements:rowcount@">

  <table  border="1">
    <tr>
      <th>Text to Replace</th>
      <th>Do Replacement</th>
      <th>Message key to use</th>
    </tr>

  <multiple name="replacements">
    <tr>
      <td>@replacements.text;noquote@</td>
      <td><input type="checkbox" name="replace_p.@replacements.rownum@" value="1" checked="1"> Yes</td>
      <td><input type="text" name="message_keys.@replacements.rownum@" value="@replacements.key@"></td>
    </tr>
  </multiple>    
  </table>

  <p>
  <input type="submit" name="process_button" value="Process ADP">
  <input type="submit" name="skip_button" value="Skip ADP">
  </p>
</form>

</blockquote>

<h3>Instructions</h3>

<p>
  Choose which message replacements to do in this file. Rather than keeping the default message key,
  try to come up with a descriptive one that says something about the semantics or context of the message.
  The text that is actually
  replaced is bold and highlighted with a yellow background in the
  "Text to Replace" column.
</p>

