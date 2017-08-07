
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Widget Reference: Date}</property>
<property name="doc(title)">Templating System Widget Reference: Date</property>
<master>
<h2>The Date Widget</h2>
<strong>
<a href="../index">Templating System</a> : <a href="index">Widget Reference</a> : Date</strong>
<h3>Overview</h3>
<p>The date widget provides a versatile HTML control for entering
dates in a variety of formats. The widget operates in conjunction
with various <code>template::util::date</code> functions in order
to validate and manipulate the user&#39;s input. Please see the
<a href="../demo/index">demo</a> pages for some examples of
the widget&#39;s behavior.</p>
<h3>The Date Object</h3>
<p>The widget&#39;s value is a Date object, defined in
<code>template::util::date</code>. The date object stores 7 fields:
the year, month, day, hours, minutes, seconds, and the format in
which these values should be displayed. The function
<code>template::util::date::create</code> can be used to
instantiate a blank date:</p>
<blockquote><pre>
proc template::util::date::create {
  {year {}} {month {}} {day {}} {hours {}} 
  {minutes {}} {seconds {}} {format "YYYY/MM/DD"}
} {
  return [list $year $month $day $hours $minutes $seconds $format]
}
</pre></blockquote>
<p>The two functions
<code>template::util::date::get_property</code> and
<code>template::util::date::set_property</code> are used to get or
set the fields of a Date object. The <code>get_property</code>
function accepts the desired field and the Date object, and returns
the value of the field:</p>
<blockquote><pre>
proc template::util::date::get_property { what date } {
...
}
</pre></blockquote>
<p>The <code>set_property</code> function accepts the field, the
Date object and the new value, and returns the modified Date
object:</p>
<blockquote><pre>
proc template::util::date::set_property { what date value } {
...
}
</pre></blockquote>
<p>The fields which can be accessed or changed are summarized
below:</p>
<table border="1" cellspacing="0" cellpadding="4">
<tr>
<th>Field</th><th>Get ?</th><th>Set ?</th><th>Meaning</th><th>Sample Value</th>
</tr><tr>
<td><code>year</code></td><td>Yes</td><td>Yes</td><td>The 4-digit year</td><td><code>2000</code></td>
</tr><tr>
<td><code>month</code></td><td>Yes</td><td>Yes</td><td>The month, January = 1</td><td><code>8</code></td>
</tr><tr>
<td><code>day</code></td><td>Yes</td><td>Yes</td><td>The day of month</td><td><code>21</code></td>
</tr><tr>
<td><code>hours</code></td><td>Yes</td><td>Yes</td><td>The hour, in 24-hour format</td><td><code>23</code></td>
</tr><tr>
<td><code>minutes</code></td><td>Yes</td><td>Yes</td><td>The minute</td><td><code>59</code></td>
</tr><tr>
<td><code>seconds</code></td><td>Yes</td><td>Yes</td><td>The second</td><td><code>59</code></td>
</tr><tr>
<td><code>format</code></td><td>Yes</td><td>Yes</td><td>The format (see below for a detailed explanation)</td><td><code>YYYY/MM/DD</code></td>
</tr><tr>
<td><code>long_month_name</code></td><td>Yes</td><td> </td><td>The symbolic month name</td><td><code>January</code></td>
</tr><tr>
<td><code>short_month_name</code></td><td>Yes</td><td> </td><td>The abbreviated month name</td><td><code>Jan</code></td>
</tr><tr>
<td><code>days_in_month</code></td><td>Yes</td><td> </td><td>The number of days in the month stored in the Date object; will
return an empty string if the month or the year are undefiend.
Takes into account the leap years.</td><td><code>29</code></td>
</tr><tr>
<td><code>short_year</code></td><td>Yes</td><td>Yes</td><td>The 2-digit year. When mutating, 2000 is added to the year if
it is less than 69; otherwise, 1900 is added to the year.</td><td><code>99</code></td>
</tr><tr>
<td><code>short_hours</code></td><td>Yes</td><td>Yes</td><td>The hour, in 12-hour format. When mutating, the hour is always
assumed to be in the "a.m." range; the <code>ampm</code>
field may be used to change this.</td><td><code>3</code></td>
</tr><tr>
<td><code>ampm</code></td><td>Yes</td><td>Yes</td><td>The meridian indicator: either <code>am</code> or
<code>pm</code>. Can be used in conjunction with the
<code>short_hour</code> field in order to completely specify the
hour.</td><td><code>am</code></td>
</tr><tr>
<td><code>not_null</code></td><td>Yes</td><td> </td><td>This field will be 1 if and only if at least one of the date
fields (year, month, date, hours, minutes or seconds) is present in
the Date object. Otherwise, this field will be 0.</td><td><code>1</code></td>
</tr><tr>
<td><code>sql_date</code></td><td>Yes</td><td> </td><td>The SQL code fragment representing the date stored in the Date
object.</td><td><code>to_date('2000/08/12 11:15:00', 'YYYY/MM/DD
HH24:MI:SS')</code></td>
</tr><tr>
<td><code>clock</code></td><td>Yes</td><td>Yes</td><td>The value of the date in the same format as the value returned
by the <code>clock seconds</code> function. The <code>clock</code>
function appears to be locale-dependent and therefore unreliable;
however, manipulating the clock value with <code>clock scan</code>
is currently the only way to perform arithmetic operations on
dates, such as adding a day, comparing two dates, etc.</td><td>(An integer representing the number of elapsed seconds)</td>
</tr>
</table>
<p>For example, the following code produces the tomorrow&#39;s date
in SQL:</p>
<blockquote><pre>

# Create a blank date
set today_date [template::util::date::create]

# Get the tomorrow&#39;s date
set clock_value [clock scan "1 day" -base [clock seconds]]
set tomorrow_date [template::util::date::set_property \
  clock $today_date $clock_value]

# Get the SQL value
set tomorrow_sql [template::util::date::get_property \
  sql_date $tomorrow_date]

</pre></blockquote>
<h3>The Date Element</h3>
<p>The widget is created with the usual <code>template::element
create</code> statement, with the datatype and widget set to
<code>date</code>. In addition, the element requires a
<code>-format</code> switch, which specifies the format for the
date, as follows:</p>
<table border="1" cellpadding="4" cellspacing="0">
<tr>
<th>Option</th><th>Format</th><th>Meaning</th>
</tr><tr>
<td><code>-format long</code></td><td><code>YYYY/MM/DD HH24:MI:SS</code></td><td>The full widget including the date and the time</td>
</tr><tr>
<td><code>-format short</code></td><td><code>YYYY/MM/DD</code></td><td>The widget capable of entering the date only, without the
time</td>
</tr><tr>
<td><code>-format time</code></td><td><code>HH24/MI/SS</code></td><td>The widget capable of entering the time only, without the
date</td>
</tr><tr>
<td><code>-format american</code></td><td><code>MM/DD/YY</code></td><td>The widget representing the more familiar American date</td>
</tr><tr>
<td><code>-format expiration</code></td><td><code>DD/YY</code></td><td>An expiration date, as it may appear on a credit card</td>
</tr><tr>
<td>
<code>-format</code><em>custom string</em>
</td><td>Custom format</td><td>See below</td>
</tr>
</table>
<p>Any other value for the <code>format</code> flag is interpreted
as a custom format string. The custom format string should consist
of format specifiers separated by any of <code>/\-.:</code> or
spaces. The valid format specifiers are as follows:</p>
<table border="1" cellpadding="4" cellspacing="0">
<tr>
<th>Format Specifier</th><th>Field</th><th>Default Widget</th><th></th>
</tr><tr>
<td><code>YYYY</code></td><td><code>year</code></td><td>Input box, 4 characters</td>
</tr><tr>
<td><code>YY</code></td><td><code>short_year</code></td><td>Input box, 2 characters</td>
</tr><tr>
<td><code>MM</code></td><td><code>month</code></td><td>Selection list</td>
</tr><tr>
<td><code>MON</code></td><td><code>month</code></td><td>Selection list of abbreviated month names</td>
</tr><tr>
<td><code>MONTH</code></td><td><code>month</code></td><td>Selection list of full month names</td>
</tr><tr>
<td><code>DD</code></td><td><code>day</code></td><td>Selection list</td>
</tr><tr>
<td><code>HH12</code></td><td><code>short_hours</code></td><td>Selection list from 1 to 12</td>
</tr><tr>
<td><code>HH24</code></td><td><code>hours</code></td><td>Selection list from 0 to 23</td>
</tr><tr>
<td><code>MI</code></td><td><code>minutes</code></td><td>Selection list from 0 to 60, skipping every 5 minutes</td>
</tr><tr>
<td><code>SS</code></td><td><code>seconds</code></td><td>Selection list from 0 to 60, skipping every 5 seconds</td>
</tr><tr>
<td><code>AM</code></td><td><code>ampm</code></td><td>Selection list of "A.M." and "P.M."</td>
</tr>
</table>
<p>Any format specifier may be followed by a lowercase
<code>t</code>, in order to force the widget to use an input box
(instead of a selection list) for entering the specified date
fragment.</p>
<p>The <code>-format</code> switch is required, but the date widget
also supports the following optional switches:</p>
<table border="1" cellpadding="4" cellspacing="0">
<tr>
<th>Switch</th><th>Meaning</th><th>Example</th>
</tr><tr>
<td nowrap="nowrap">
<code>-</code><em>field</em><code>_interval</code><em>interval</em>
</td><td>Specifies a custom interval for the given field, as a list of
three values: the starting value, the ending value, and the
step</td><td nowrap="nowrap"><code>-minute_interval {0 59 5}</code></td>
</tr><tr>
<td><code>-help</code></td><td>Causes the date widget to display a description of each date
fragment widget showing the purpose of the widget, such as
"Year" or "24-Hour"</td><td><code>-help</code></td>
</tr>
</table>
<p>Examples of various Date widgets can be found on the <a href="/ats/demo/index">demo</a> pages.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->