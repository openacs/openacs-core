<html>
<head>
   <title>@title@</title>
</head>
<body bgcolor=ffffff text=000000 leftmargin=15 topmargin=5 marginwidth=15 marginheight=5>
<h2>@title@</h2>
@context_bar@
<hr>

<form method=GET action=search>
  <small>
    <a href=@url_advanced_search@>Advanced Search</a>
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

<slave>