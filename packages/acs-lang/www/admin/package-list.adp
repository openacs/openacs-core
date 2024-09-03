<master>
 <property name="doc(title)">@page_title;literal@</property>
 <property name="context">@context;literal@</property>

<formtemplate id="search">
<p>Search <formwidget id="search_locale"> for <formwidget id="q"> <input type="submit" value="Search">
</formtemplate>

<include src="/packages/acs-lang/lib/conflict-link" locale="@current_locale;literal@" >

<listtemplate name="packages"></listtemplate>
