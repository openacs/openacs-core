<master src="../box-master">
<property name="title"><a href="/forums/">@title@</a></property>

<multiple name=forum_posts>
  <if @forum_posts.rownum@ le @n_posts@>
    <div class="forum"> 
      <p class="title">
        <a href="/forums/forum-view?forum_id=@forum_posts.forum_id@">@forum_posts.forum_name@</a>
      </p>
      <group column="forum_id"> 
        <p class="item">
        
	<a href="/forums/message-view?message_id=@forum_posts.message_id@">@forum_posts.subject@</a>
        </p>
      </group> 

    </div>
  </if>
</multiple>

<if @forum_posts:rowcount@ eq 0>
 There are no posts.
</if>

<if @forum_posts:rowcount@ gt @n_posts@>
  <span class="more"><a href="/forums">more posts</a>...</span>
</if>
