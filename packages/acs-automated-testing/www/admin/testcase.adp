<master>
<property name="title">@title;noquote@</property>
<property name="context">@context;noquote@</property>

<html>
  <body>
  <table width="100%"><tr><td bgcolor=#e4e4e4>
    <h2> Testcase @testcase_id@ (@package_key@)</h2>
    <blockquote>
    <dt><b>Description:</b></dt><dd>@testcase_desc@</dd>
    <dt><b>Defined in file:</b></dt><dd>@testcase_file@</dd>
    <dt><b>Categories:</b></dt><dd>@testcase_cats@</dd>
    <if @bug_blurb@ not nil>
      <dt><b>Bugs:</b></dt><dd>This test case covers OpenACS bug number(s):
      @bug_blurb;noquote@</dd>
    </if>
    <if @proc_blurb@ not nil>  
      <dt><b>Procs:</b></dt><dd>This test case covers OpenACS proc(s):
      @proc_blurb;noquote@</dd>
    </if>
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

  <blockquote>
    <b>&raquo;</b>
    <a href="rerun?testcase_id=@testcase_id@&package_key=@package_key@&quiet=@quiet@">Rerun this test case</a>
    <br>
    <b>&raquo;</b>
    <a href="@resource_file_url@">Resource test definition file</a>
    <br>
    <b>&raquo;</b>
    <a href="@return_url@">Back to testcase list</a>
  </blockquote>

<p>
<b>Results</b> 
[<if @quiet@ eq "1">
   <strong> quiet </strong> | 
   <a href="@verbose_url@">verbose</a>
</if><else>
   <a href="@quiet_url@">quiet</a>
   | <strong> verbose </strong>
</else>]
</p>

<if @quiet@ false>
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
        <if @tests.rownum@ odd>
          <tr>
        </if>
        <else>
          <tr bgcolor="#e9e9e9">
        </else>
            
          <td> @tests.timestamp@ </td>
          <td>
            <if @tests.result@ eq "fail">
               <span style="background-color: red; color: white; font-weight: bold; padding: 4px;">FAILED
            </if>
            <if @tests.result@ eq "log">
              <span style="color: #10b010">log
            </if>
            <if @tests.result@ eq "pass">
              <span style="color: green">passed
            </if>
            <if @tests.result@ eq "fail" or @tests.result@ eq "log" or @tests.result@ eq "pass">
              </span>
            </if>
            <else>
              @tests.result@
            </else>
          </td>
          <td> <pre>@tests.notes@</pre> </td>
  
        </tr>
    </multiple>
  </else>
  </table>
</if>
<else>
  <table>
    <tr>
      <th>Result</th>
      <th>Count</th>
    </tr>
    <multiple name="tests_quiet">
    <tr>
      <td>@tests_quiet.result@</td>
      <td>@tests_quiet.count@</td>
    </tr>
    </multiple>
  </table>
</else>

  <blockquote>
    <b>&raquo;</b>
    <a href="rerun?testcase_id=@testcase_id@&package_key=@package_key@&quiet=@quiet@">Rerun this test case</a>
    <br>
    <b>&raquo;</b>
    <a href="@resource_file_url@">Resource test definition file</a>
    <br>
    <b>&raquo;</b>
    <a href="@return_url@">Back to testcase list</a>
  </blockquote>

</html>
