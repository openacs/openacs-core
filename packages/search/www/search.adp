<master>
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<form method=GET action=search>
  <small>
    <a href=@url_advanced_search@>#search.Advanced_Search#</a>
    <br>
    <input type=text name=q size=31 maxlength=256 value="@query@">
    <input type=submit value="#search.Search#" name=t>
    <input type=submit value="#search.Feeling_Lucky#" name=t>
  </small>
</form>
<if @t@ eq "Search">
  <i>#search.lt_Tip_In_most_browsers_#</i><br><br>
</if>

	<if @and_queries_notice_p@ eq 1>
      	  <font color=6f6f6f>
          #search.The#
          [<a href=help/basics#and>#search.details#</a>]<br>
        </font>
	</if>
	<if @nstopwords@ eq 1>
        <font color=6f6f6f>
          #search.lt_bstopwordsb_is_a_very#
          [<a href=help/basics#stopwords>#search.details#</a>]<br>
        </font>
	</if>
	<if @nstopwords@ gt 1>
      	  <font color=6f6f6f>
          #search.lt_The_following_words_a# <b>@stopwords@</b>.
          [<a href=help/basics#stopwords>#search.details#</a>]<br>
      	  </font>
	</if>

<multiple name="searchresult">
	<if @searchresult.title_summary@ nil>
  		<a href=@searchresult.url_one@>#search.Untitled#</a><br>
	</if>	
	<else>
	  <a href=@searchresult.url_one@>@searchresult.title_summary;noquote@</a><br>
	</else>
	<if @searchresult.txt_summary@ nil>	
	</if>
	<else>	
	@searchresult.txt_summary;noquote@<br>	
	</else>
	<font color=green>@searchresult.url_one@</font><br><br>
</multiple>

<if @count@ eq 0>
  Your search - <b>@query@</b> - did not match any documents.
  <br>#search.lt_No_pages_were_found_c#<b>@query@</b>".
  <br><br>#search.Suggestions#
  <ul>
    <li>#search.lt_Make_sure_all_words_a#
    <li>#search.lt_Try_different_keyword#
    <li>#search.lt_Try_more_general_keyw#
    <if @nquery@ gt 2>
      <li>#search.Try_fewer_keywords#
    </if>
  </ul>
</if>
<else>
  <table width=100% bgcolor=3366cc border=0 cellpadding=3 cellspacing=0>
    <tr><td>
      <font color=white>
        #search.Searched_for_query#
      </font>
    </td><td align=right>
      <font color=white>
        #search.Results# <b>@low@-@high@</b> #search.of_about# <b>@count@</b>#search.________Search_took# <b>@elapsed@</b> #search.seconds# 
      </font>     
    </td></tr>
  </table>
  <br clear=all>
</else>

<if @from_result_page@ lt @to_result_page@>
  <center>

    <small>#search.Result_page#</small>

    <if @from_result_page@ lt @current_result_page@>
      <small><a href=@url_previous@><font color=0000cc><b>#search.Previous#</b></font></a></small>
    </if>
    &nbsp;@choice_bar;noquote@&nbsp;
    
    <if @current_result_page@ lt @to_result_page@>
	<small><a href=@url_next@><font color=0000cc><b>#search.Next#</b></font></a></small>
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
      <font size=-1>#search.lt_Try_your_query_on_stw#</font></center>
    </center>
  </if>
</if>
