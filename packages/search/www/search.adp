<master>
  <property name="title">@page_title@</property>
  <property name="context">@context;noquote@</property>
  <property name="in_search_p">t</property>
  <property name="robots">noindex,nofollow</property>

  <property name="header_stuff">
    <style type="text/css">
    .hint {
      font-style: italic;
    }
    .url {
      color: green;
    }
    .result {
      margin: 1em 0 0 0;
      padding: 0 0 0 1em;
      border-left: 3px solid grey;
    }
    .result b {
      background: yellow;
      padding: 0 3px;
    }
    </style>
  </property>

  <form method="get" action="search">
    <input type="text" name="q" size="60" maxlength="256" value="@query@" />
    <input type="submit" value="#search.Search#" name="t" />
    <!--<input type=submit value="#search.Feeling_Lucky#" name="t" />-->
  </form>
  <p style="margin: 0 0 1em 1em; padding: 0; float: right;"><a href="@url_advanced_search@">#search.Advanced_Search#</a></p>
  <if @empty_p@ true>
    <p class="hint">#search.lt_You_must_specify_some#</p>
  </if><else>
    <if @and_queries_notice_p@ eq 1>
      <p class="hint">#search.and_not_needed# [<a href="help/basics#and">#search.details#</a>]</p>
    </if>
    <if @nstopwords@ eq 1>
      <p class="hint">#search.lt_bstopwordsb_is_a_very# [<a href="help/basics#stopwords">#search.details#</a>]</p>
    </if>
    <if @nstopwords@ gt 1>
      <p class="hint">#search.lt_The_following_words_a# [<a href="help/basics#stopwords">#search.details#</a>]</p>
    </if>

    <multiple name="searchresult">
      <div class="result">
        <if @searchresult.title_summary@ nil>
          <a href="@searchresult.url_one@">#search.Untitled#</a>
        </if>
        <else>
          <div class="title"><a href="@searchresult.url_one@">@searchresult.title_summary;noquote@</a><!-- @searchresult.object_id@ --> </div>
        </else>
        <if @searchresult.txt_summary@ not nil>	
          <div class="search-match">@searchresult.txt_summary;noquote@</div>
        </if>
        <div class="url">@searchresult.url_one@</div>
      </div>
    </multiple>

    <if @count@ eq 0>
      <p>#search.lt_No_pages_were_found_c#</p>
      <p>#search.Suggestions#</p>
      <ul>
        <li>#search.lt_Make_sure_all_words_a#</li>
        <li>#search.lt_Try_different_keyword#</li>
        <li>#search.lt_Try_more_general_keyw#</li>
        <if @nquery@ gt 2>
          <li>#search.Try_fewer_keywords#</li>
        </if>
      </ul>
    </if>
    <else>
      <p>#search.Searched_for_query#</p>
      <p>#search.Results_count#</p>
    </else>

    <if @from_result_page@ lt @to_result_page@>
      <div class="search-pages">
        #search.Result_page#
        <if @from_result_page@ lt @current_result_page@>
          <a href="@url_previous@">#search.Previous#</a>
        </if>
        &nbsp;@choice_bar;noquote@&nbsp;
        <if @current_result_page@ lt @to_result_page@>
          <a href="@url_next@">#search.Next#</a>
        </if>
      </div>
    </if>
    <if @count@ gt 0>
      <div>
        <form method="get" action="search">
          <input type="text" name="q" size="60" maxlength="256" value="@query@" />
          <input type="submit" value="#search.Search#" />
        </form>
      </div>

      <if @stw@ not nil>
        <p>#search.lt_Try_your_query_on_stw#</p>
      </if>
    </if>
  </else>
