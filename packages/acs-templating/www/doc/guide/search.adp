
<property name="context">{/doc/acs-templating {Templating}} {Templating System User Guide: Search-and-Select
Forms}</property>
<property name="doc(title)">Templating System User Guide: Search-and-Select
Forms</property>
<master>
<h2>Implementing Search-and-Select Forms</h2>
<p>Form designers are often confronted by the need to provide users
with a way to choose from hundreds or even thousands of potential
options, exceeding the practical capacity of a select list or set
of checkboxes or radio buttons. One common solution is to allow the
user to select from a search result:</p>
<ol>
<li><p>The user is prompted to enter or choose some search criteria.
For example, travel sites typically begin the reservation process
by prompting the user to enter a city of origin and
destination.</p></li><li>
<p>The search may return any number of results. Depending on the
specific application, the system may require the user to make one
choice, or allow multiple selections. If the search returns no
results, the system returns the user to the search form to modify
the search criteria and search again.</p><p>To continue the travel site example, if an exact match is found
for the cities entered by the user, the system immediately returns
a list of flights. If several possible matches are found, the
system prompts the user to choose a city before proceding. If no
matches are found, the sytem prompts the user to search again.</p>
</li>
</ol>
<p>To illustrate how to implement this type of page flow using the
templating system, we will build the framework for a simple
user-management interface. Required actions for such an interface
might include editing basic user properties, changing user
permissions or adding users to roles or groups.</p>
<p>The simplest way to implement this page flow using the
templating system is to create a single page that conditionally
includes two different forms:</p>
<ol>
<li><p>Say the administrator wishes to edit the name and screen name of
a user. The administrator requests a page, <tt>user-edit.acs</tt>.
The page looks for a query parameter named <tt>user_id</tt> to
specify which user to edit.</p></li><li><p>Initially, <tt>user_id</tt> is not specified. In this case, the
page includes a user search form.</p></li><li><p>The user enters part of a user name or screen name and submits
the form, which returns to the same URL with the query parameter
<tt>user_search</tt>. If this parameter is defined, the page
queries the database for potential matches.</p></li><li><p>If one match is found, the page sets a <tt>user_id</tt> variable
and includes the actual user edit form.</p></li><li><p>If multiple matches are found, the page includes a listing of
users. The name of each each user is linked back to the same page,
with the appropriate <tt>user_id</tt>. The page prompts the
administrator to choose one. A link is also provided with no
<tt>user_id</tt> so that the administrator may search again.</p></li><li><p>If the administrator chooses a user, the page detects the
<tt>user_id</tt> and displays the edit form.</p></li>
</ol>
<p>A working implementation of this example is provided in the
files <tt>demo/user-edit.tcl</tt> and <tt>demo/user-edit.adp</tt>.
You must execute the demo data file (<tt>demo/demo.sql</tt>) for
the page to function.</p>
<p>Try the following scenarios:</p>
<ol>
<li>Submit the search form without entering any search
criteria.</li><li>Submit the search form with obscure criteria that does not
yield a match.(i.e. <tt>zzzzz</tt>).</li><li>Submit the search form with criteria likely to produce multiple
results (i.e. <tt>e</tt>).</li><li>Submit the search form with criteria likely to product a single
result (i.e. <tt>Sally</tt>).</li>
</ol>
<hr>
<a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
