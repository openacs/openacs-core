<master>
  <property name="title">Server Error</property>

<p>
  There was a server error processing your request. We apologize.
</p>

<if @stacktrace@ not nil>
  <p>
    Here is a detailed dump of what took place at the time of the error, which may assist a programmer in tracking down the problem:
  </p>
  <blockquote><pre>@stacktrace@</pre></blockquote>
</if>
<else>
  The error has been logged and will be investigated by our system
  programmers.
</else>
