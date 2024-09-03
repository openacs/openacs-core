<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<blockquote>
@filter_html;noquote@

<listtemplate name="parameters_list"></listtemplate>
</blockquote>

<if @return_url@ not nil>
<a href="@return_url@" class="button">@return_label@</a>
</if>
