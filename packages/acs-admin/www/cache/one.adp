  <master>
    <property name="title">util_memoize: @pattern@</property>
    <property name="context">{./ "Cache data"} "one entry"</property>

    <form action="flush" method="post">
      <input type="hidden" name="type" value="one">
      <input type="hidden" name="pattern" value="@pattern@">
      <input type="hidden" name="raw_date" value="@raw_date@">
      <input type="hidden" name="key" value="@safe_key@">
      Cached value at @time@.
      <input type="submit" value="Flush">
    </form>
    <hr>
    <b>Key:</b>
    <blockquote>
      <pre>@key@</pre>
    </blockquote>
    <hr>
    <b>Value:</b>
    <blockquote>
      @value@
    </blockquote>

    <p align=right><font size=-1><code>$Id$</code></font></p>
