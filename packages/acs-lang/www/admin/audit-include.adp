<if @current_message_author@ not nil>
<p>
Current translation by @current_message_author@ at @current_message_date@
</p>
</if>

<if @audit_trail:rowcount@ gt 0>
<p>
Translation History:
<ul>
<multiple name="audit_trail">
<li>"@audit_trail.message@" by @audit_trail.creation_user@ at @audit_trail.creation_date@</li>
</multiple>
</ul>
</p>
</if>

<if @trail_counter@ gt 0>
Original translation: "@original_message@"
</if>
