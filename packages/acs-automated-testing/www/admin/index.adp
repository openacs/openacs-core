<master src="master">
<property name="title">@title@</property>
<property name="context_bar">@context_bar@</property>
<html>
  <body>
  <table border=0 cellspacing=0 cellpadding=3 width="100%">
    <tr>
      <th bgcolor="#ECECEC">Category</th>
      <th bgcolor="#ECECEC">Mode</th>
      <th bgcolor="#ECECEC">View by</th>
    </tr>
    <tr>
      <td align=center> [
      <if @by_category@ eq "">
         <strong> all </strong>
      </if><else>
         <a href="index?by_package_key=@by_package_key@&view_by=@view_by@&quiet=@quiet@">all</a>
      </else>
      <multiple name="all_categories">
        |
        <if @by_category@ eq @all_categories.name@>
           <strong> @all_categories.name@ </strong>
        </if><else>
           <a href="index?by_package_key=@by_package_key@&view_by=@view_by@&by_category=@all_categories.name@&quiet=@quiet@">@all_categories.name@</a>
        </else>
      </multiple> ]
    </td>
    <td align=center> [
      <if @quiet@ eq "1">
         <strong> quiet </strong> | 
         <a href="index?by_package_key=@by_package_key@&view_by=@view_by@&by_category=@by_category@&quiet=0">verbose</a>
      </if><else>
         <a href="index?by_package_key=@by_package_key@&view_by=@view_by@&by_category=@by_category@&quiet=1">quiet</a>
         | <strong> verbose </strong>
      </else>  ]
    </td>
    <td align=center> [
      <if @view_by@ eq "" or @view_by@ eq "package">
         <strong> package </strong> | 
         <a href="index?by_package_key=@by_package_key@&view_by=testcase&by_category=@by_category@&quiet=@quiet@">testcase</a>
      </if><else>
         <a href="index?view_by=package&by_category=@by_category@&quiet=@quiet@">package</a>
         | <strong> testcase </strong>
      </else>  ]
    </td>
    </tr>
  </table>
  <p>
  <ul>
    <li> <a href="rerun?package_key=@by_package_key@&category=@by_category@&view_by=@view_by@&quiet=@quiet@"> Re-run </a> displayed test cases </a> </li>
    <li> <a href="clear?package_key=@by_package_key@&category=@by_category@&view_by=@view_by@&quiet=@quiet@"> Clear </a> test result data</a> </li>
  </ul>
  <p>
  <if @view_by@ eq "package">
    <table width="100%">
    <tr>
        <th bgcolor=#c0c0c0>Package key</th>
        <th bgcolor=#c0c0c0>Total run testcases</th>
        <th bgcolor=#c0c0c0>Passes</th>
        <th bgcolor=#c0c0c0>Fails</th>
        <th bgcolor=#c0c0c0>Result</th>
    </tr>
    <multiple name="packageinfo">
      <tr>
        <td> <a href="index?by_package_key=@packageinfo.key@&view_by=testcase&quiet=@quiet@">@packageinfo.key@</a></td>
        <if @packageinfo.total@ eq "0">
          <td> No Data </td><td>-</td><td>-</td>
          <td>
              <font color=#ff0000> fail </font>
          </td>
        </if><else>
          <td> @packageinfo.total@ </td>
          <td> @packageinfo.passes@ </td>
          <td> @packageinfo.fails@ </td>
          <td>
            <if @packageinfo.fails@ gt 0>
              <font color=#ff0000> fail </font>
            </if><else>
              passed
            </else>
          </td>
        </else>
      </tr>
    </multiple>
    </table>
  </if><else>
    <table width="100%">
    <tr>
        <th bgcolor=#c0c0c0>Package key</th>
        <th bgcolor=#c0c0c0>Testcase id</th>
        <th bgcolor=#c0c0c0>Categories</th>
        <th bgcolor=#c0c0c0>Description</th>
        <th bgcolor=#c0c0c0>Timestamp</th>
        <th bgcolor=#c0c0c0>Passes</th>
        <th bgcolor=#c0c0c0>Fails</th>
        <th bgcolor=#c0c0c0>Result</th>
    </tr>
    <multiple name="tests">
      <if @tests.marker@ eq 1>
        <tr><td colspan=8 align=centre bgcolor=#f0f0f0><strong>@tests.package_key@</strong></td></tr>
      </if>
      <tr valign=top>
        <td> @tests.package_key@ </td>
        <td> <a href="testcase?testcase_id=@tests.id@&package_key=@tests.package_key@&view_by=@view_by@&category=@by_category@&quiet=@quiet@">@tests.id@</a></td>
        <td> @tests.categories@ </td>
        <td> @tests.description@ </td>
        <if @tests.timestamp@ eq "">
          <td> No Data </td><td>-</td><td>-</td>
          <td>
              <font color=#ff0000> fail </font>
          </td>
        </if><else>
          <td> @tests.timestamp@ </td>
          <td> @tests.passes@ </td>
          <td> @tests.fails@ </td>
          <td>
            <if @tests.fails@ gt 0>
              <font color=#ff0000> fail </font>
            </if><else>
              passed
            </else>
          </td>
        </else>
      </tr>
    </multiple>
    </table>
  </else>
  <p>
  <ul>
    <li> <a href="rerun?package_key=@by_package_key@&category=@by_category@&view_by=@view_by@&quiet=@quiet@"> Re-run </a> displayed test cases </a> </li>
    <li> <a href="clear?package_key=@by_package_key@&category=@by_category@&view_by=@view_by@&quiet=@quiet@"> Clear </a> test result data</a> </li>
  </ul>

  </body>
</html>
