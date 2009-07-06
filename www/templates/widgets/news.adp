  <div class="rss-feed">
	<a href="/news/rss/rss.xml" title="Subscribe to news via RSS"><img src="/resources/rss-support/xml.gif" alt="Subscribe via RSS" style="border:0"> Syndication Feed</a>
  </div>

  <h1>@title@</h1>

  <multiple name=news_items>
	<if @news_items.rownum@ le @n_news_items@>
	  <div class="news-item">
		<h2 class="item-title">
		  <a href="/news/item?item_id=@news_items.item_id@">@news_items.publish_title@</a>
		  @news_items.pretty_publish_date@
		</h2>
		<div class="item-content">@news_items.publish_body;noquote@</div>
	  </div>
	</if>
  </multiple>

  <if @news_items:rowcount@ eq 0>
	<div class="item-content">
	  <p>There are no recent news items. </p>
	  <p>See <a href="/news/?view=archive">archived news items</a>.</p>
	</div>
  </if>

  <if @news_items:rowcount@ gt @n_news_items@>
	<div class="more"><a href="/news/">More news...</a></div>
  </if>
