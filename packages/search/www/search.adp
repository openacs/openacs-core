<master>
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<form method=GET action=search>
  <small>
    <a href="@url_advanced_search@">Advanced Search</a>
    <br>
    <input type=text name=q size=31 maxlength=256 value="@query@">
    <input type=submit value="Search" name=t>
    <input type=submit value="Feeling Lucky" name=t>
  </small>
</form>
<if @t@ eq "Search">
  <i>Tip: In most browsers you can just hit the return key instead of clicking on the search button.</i><br><br>
</if>

	<if @and_queries_notice_p@ eq 1>
      	  <font color=6f6f6f>
          The "<b>AND</b>" operator is unnecessary -- we include all search terms by default. 
          [<a href=help/basics#and>details</a>]<br>
        </font>
	</if>
	<if @nstopwords@ eq 1>
        <font color=6f6f6f>
          "<b>@stopwords@</b>" is a very common word and was not included in your search.
          [<a href=help/basics#stopwords>details</a>]<br>
        </font>
	</if>
	<if @nstopwords@ gt 1>
      	  <font color=6f6f6f>
          The following words are very common and were not included in your search: <b>@stopwords@</b>.
          [<a href=help/basics#stopwords>details</a>]<br>
      	  </font>
	</if>

<multiple name="searchresult">
	<if @searchresult.title_summary@ nil>
  		<a href=@searchresult.url_one@>Untitled</a><br>
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
  <br>No pages were found containing "<b>@query@</b>".
  <br><br>Suggestions:
  <ul>
    <li>Make sure all words are spelled correctly.
    <li>Try different keywords.
    <li>Try more general keywords.
    <if @nquery@ gt 2>
      <li>Try fewer keywords.
    </if>
  </ul>
</if>
<else>
  <table width=100% bgcolor=3366cc border=0 cellpadding=3 cellspacing=0>
    <tr><td>
      <font color=white>
        Searched for: @query@
      </font>
    </td><td align=right>
      <font color=white>
        Results <b>@low@-@high@</b> of about <b>@count@</b>.
        Search took <b>@elapsed@</b> seconds. 
      </font>     
    </td></tr>
  </table>
  <br clear=all>
</else>

<if @from_result_page@ lt @to_result_page@>
  <center>

    <small>Result page:</small>

    <if @from_result_page@ lt @current_result_page@>
      <small><a href=@url_previous@><font color=0000cc><b>Previous</b></font></a></small>
    </if>
    &nbsp;@choice_bar;noquote@&nbsp;
    
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
      <font size=-1>Try your query on: @stw;noquote@</font></center>
    </center>
  </if>
</if>