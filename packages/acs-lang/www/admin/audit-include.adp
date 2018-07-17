<if @audit:rowcount;literal@ gt 0>
  <ul>
    <multiple name="audit">
      <li>
        <if @audit.new_message@ ne @audit.old_message@>
          "@audit.old_message@" -> "@audit.new_message@"
        </if>
        <else>
          "@audit.new_message@"
        </else>
        <group column="old_new_message">
          <if @audit.comment_text@ not nil or @audit.new_message@ ne @audit.old_message@>
            <if @audit.comment_text@ not nil>
              <blockquote>
                @audit.comment_text@
              </blockquote>
            </if>
            <p>
              -- <em><a href="@audit.creation_user_url@">@audit.creation_user_name@</a> at @audit.creation_date@</em>
            </p>
          </if>
        </group>
      </li>
    </multiple>
  </ul>
</if>
<else>
  <p>
    No changes or comments.
  </p>
</else>
