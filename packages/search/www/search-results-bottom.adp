<if @from_result_page@ lt @to_result_page@>
  <center>

    <small>Result page:</small>

    <if @from_result_page@ lt @current_result_page@>
      <small><a href=@url_previous@><font color=0000cc><b>Previous</b></font></a></small>
    </if>
    &nbsp;@choice_bar@&nbsp;
    
    <if @current_result_page@ lt @to_result_page@>
	<small><a href=@url_next@><font color=0000cc><b>Next</b></font></a></small>
    </if>
  </center>
</if>
<if @count@ gt 0>
  <center>
    <table border=0 cellpadding=3 cellspacing=0>
      <tr><td nowrap>
        <form method=GET action=search>
          <center>
            <small>
              <input type=text name=q size=31 maxlength=256 value="@query@">
              <input type=submit value=Search>
            </small>
          </center>
        </form>
      </td></tr>
    </table>
  </center>

  <if @stw@ not nil>
    <center>
      <font size=-1>Try your query on: @stw@</font></center>
    </center>
  </if>
</if>
</body>
</html>