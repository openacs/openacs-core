<master>
  <property name="title">#search.Search#</property>
  <property name="context">#search.Search#</property>

  <if @driver_p@ true> 
    <form method="GET" action="search">
      <input type="text" name="q" size="80" maxlength="256" />
      <input type="submit" value="#search.Search#" name="t" />
      <!--<input type="submit" value="#search.Feeling_Lucky#" name="t" />-->
    </form>
    <a href="advanced-search">#search.Advanced_Search#</a>
  </if>
  <else>
    #search.no_driver_contact_webmaster#
  </else>
