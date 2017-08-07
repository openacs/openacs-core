<formtemplate id="list-filters-@name@">
<p><formwidget id="submit"></p>
<multiple name="filters">
<if @filters.selected_p;literal@ true>
    <if @filters.widget@ not nil and @filters.widget@ ne "hidden">
         <p>
         @filters.filter_label@
         [ <a href="@filters.clear_one_url@">x</a> ]
         <br>
    </if>
    <formwidget id="@filters.filter_name@">
    <if @filters.widget@ not nil and @filters.widget@ ne "hidden">
        </p>
    </if>
</if>
</multiple>
<p><formwidget id="submit"></p>
</formtemplate>
<if 0><formtemplate id="list-filter-add-@name@" style="inline"></formtemplate></if>
