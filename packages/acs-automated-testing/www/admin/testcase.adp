<master src="master">
<property name="title">@title@</property>
<property name="context_bar">@context_bar@</property>

<html>
  <body>
  <table width="100%"><tr><td bgcolor=#e4e4e4>
    <h2> Testcase @testcase_id@ (@package_key@)</h2>
    <blockquote>
    <dt><b>Description:</b></dt><dd>@testcase_desc@</dd>
    <dt><b>Defined in file:</b></dt><dd>@testcase_file@</dd>
    <dt><b>Categories:</b></dt><dd>@testcase_cats@</dd>
    <if @testcase_inits@ ne "">
      <dt><b>Initialisation Classes:</b></dt><dd>@testcase_inits@</dd>
    </if>
    <if @fails@ gt 0 and @testcase_on_error@ ne "">
      <dt><font color=#e00000><b>Testcase failure error response:</b></font></dt>
      <dd>@testcase_on_error@</dd>
    </if>
    <if @showsource@ eq 1>
      <multiple name="bodys">
        <dt> <b> Body @bodys.body_number@ source </b> </dt>
        <dd><pre>
          @bodys.body@
        </pre></dd>
      </multiple>
    </if>
    </blockquote>
  </td></tr></table>
  <if @showsource@ eq 0>
    [<a href="testcase?testcase_id=@testcase_id@&package_key=@package_key@&showsource=1&quiet=@quiet@">
       show testcase source
     </a>]
  </if>
  <else>
    [<a href="testcase?testcase_id=@testcase_id@&package_key=@package_key@&showsource=0&quiet=@quiet@">
       hide testcase source
     </a>]
  </else>
  <p>

<b>Results</b>
  <table>
  <tr><th bgcolor=#c0c0c0>Time</th>
      <th bgcolor=#c0c0c0>Result</th>
      <th bgcolor=#c0c0c0>Notes</th>
  </tr>
  <if @tests:rowcount@ eq 0>
    <tr><td> No results </td></tr>
  </if>
  <else>
    <multiple name="tests">
      <tr>
          
        <td> @tests.timestamp@ </td>
        <td>
          <if @tests.result@ eq "fail">
            <font color=#ff0000>
          </if>
          <if @tests.result@ eq "log">
            <font color=#10b010>
          </if>
          @tests.result@
          <if @tests.result@ eq "fail" or @tests.result@ eq "log">
            </font>
          </if>
        </td>
        <td> @tests.notes@ </td>
  
      </tr>
    </multiple>
  </else>
  </table>
  <ul>
    <li> <a href="rerun?testcase_id=@testcase_id@&package_key=@package_key@&quiet=@quiet@">Rerun</a> this test case </li>
    <li> <a href="index?view_by=testcase&quiet=@quiet@">Back</a> to index </li>
  </ul>

</html>
