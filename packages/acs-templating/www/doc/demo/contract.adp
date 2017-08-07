<master>
<property name="doc(title)">User Input Form</property>

<form action="contract-2">
  <table>
    <tr><th>How many?</th><td><input name="count" value="2"></td>
        <td>(not 13)</td></tr>
    <tr><th>Give me a noun:</th><td><input name="noun" value="goose"></td></tr>
    <tr>
      <th>Any irregular plural?</th>
      <td><input name="plural" value="geese"></td>
      <td>(optional)</td>
    </tr>
    <tr>
      <th colspan="2"><input type="submit" value="Go">
      <if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if>
      </th>
    </tr>
  </table>
</form>
