<a href="@namespace.url@.html">@namespace.name@</a>
    <if @namespace.author@ not nil>
       <small>by @namespace.author@</small>
    </if>
    <blockquote>
        @namespace.overview@
        <if @namespace.see@ not nil>
	<p>See:<multiple name=see_info > @see_info.type@ <a href="@see_info.url@">@see_info.name@</a><if @see_info.rownum@ lt @see_info:rowcount@>,</if></multiple>	
        </if>
    </blockquote>


