<if @switchable_count@ gt 1>
  <multiple name="locale_list">
    <if @current_locale@ eq @locale_list.locale@>
      <b>@locale_list.l10n_label@</b>
    </if>
    <else>
      <a href="@locale_list.switch_url@">@locale_list.l10n_label@</a>
    </else>
  </multiple>
</if>
<if @change_locale_url@ not nil>
  <a href="@change_locale_url@">@change_locale_text@</a>
</if>
<if @lang_admin_p@>
      <a class="button" href="@lang_admin_url@">@lang_admin_text@</a>
</if>