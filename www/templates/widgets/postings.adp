<h2>@title@</h2>

  <multiple name=forum_posts>
	<if @forum_posts.rownum@ le @n_posts@>
	  <div class="forum"> 
		<h3 class="forum-title">
		  <a href="/forums/forum-view?forum_id=@forum_posts.forum_id@">@forum_posts.forum_name@</a>
		</h3>
		<ul class="forum-content">
		  <group column="forum_id"> 
			<li>
			  <a href="/forums/message-view?message_id=@forum_posts.message_id@">@forum_posts.subject;noquote@</a>
			</li>
		  </group> 
		</ul>
	  </div>
	</if>
  </multiple>

  <if @forum_posts:rowcount@ eq 0>
	<p>There are no posts.</p>
  </if>

  <if @forum_posts:rowcount@ gt @n_posts@>
	<div class="more"><a href="/forums">More posts...</a></div>
  </if>
