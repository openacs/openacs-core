<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

  <if @page_fragment_cache_p@ true>
    <p>
      <form name="searchfrags" action="/ds/search">
        <input type="hidden" name="request" value="@request@">
        <input type="text" name="expression" value="">
        <input type="submit" name="search" value="Search">
      </form>
    </p></if>

@body;noquote@
<if @expired_p@ eq 0>
  <if @dbreqs:rowcount@ gt 0>
    <listfilters name="dbreqs" style="inline-filters"></listfilters>
    <listtemplate name="dbreqs"></listtemplate>
  </if>

  <if @profiling:rowcount@ gt 0>
    <h3>Profiling Information</h3>
    <listtemplate name="profiling"></listtemplate>
    <if @page_fragment_cache_p@ true>
      <p>
        <form name="searchfrags" action="search">
          <input type="hidden" name="request" value="@request@">
          <input type="text" name="expression" value="">
          <input type="submit" name="search" value="Search">
        </form>
      </p>
    </if>
  </if>
</if>
