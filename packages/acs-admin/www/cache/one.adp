  <master>
    <property name="title">@page_title;noquote@</property>
    <property name="context">@context;noquote@</property>

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
      <pre>@key;noquote@</pre>
    </blockquote>
    <hr>
    <b>Value:</b>
    <blockquote>
      @value;noquote@
    </blockquote>

