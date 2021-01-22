<master>
  <property name="doc(title)">Search</property>
  <property name="context">@context;literal@</property>

  <p>
      <form name="searchfrags" action="search">
        <input type="hidden" name="request" value="@request@">
        <input type="text" name="expression" value="@expression@">
        <input type="submit" name="search" value="Search">
      </form>
    </p>

  <if @gone_p@ false> 
    <if @matches:rowcount@ gt 0>
      <multiple name="matches">
        <div style="border-bottom: 1px solid black;"><p>@matches.file_links;noquote@ <strong>@matches.page@</strong> @matches.size@ bytes</p><pre>@matches.excerpt;noquote@</pre></div>
      </multiple>
    </if>
    <else> 
      <p>No match</p>
    </else>
  </if>
  <else>
    <p>That request is invalid or has expired from the cache.</p>
  </else>
 