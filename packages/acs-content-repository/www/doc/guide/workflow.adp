
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository Developer Guide: Workflow}</property>
<property name="doc(title)">Content Repository Developer Guide: Workflow</property>
<master>
<h2>Applying Workflow to Content Items</h2>
<strong>
<a href="../index">Content Repository</a> : Developer
Guide</strong>
<p>This document describes the workflow API calls necessary to
apply a simple workflow to a content item.</p>
<h3>Workflow Description</h3>
<p>Most publishers wish to follow some variation of the following
workflow:</p>
<table border="1" cellspacing="0" cellpadding="4">
<tr bgcolor="#CCCCCC">
<th>State</th><th>Task</th><th>Description</th>
</tr><tr>
<td>Created</td><td>Authoring</td><td>The publisher has created the item.</td>
</tr><tr>
<td>Authored</td><td>Editing</td><td>The author has written the item.</td>
</tr><tr>
<td>Edited</td><td>Publishing</td><td>The editor has approved the item.</td>
</tr><tr>
<td>Published</td><td>None</td><td>The publisher has approved the item.</td>
</tr>
</table>
<p>At any point in the workflow, an assigned user should be able to
check out an item, such that other users are advised that someone
is working on it. When checking an item in, a user should have up
to three options:</p>
<ol>
<li>Check the item in but do not mark the task as finished
(allowing someone else to work on the task. The currently enabled
task (whether it is authoring, editing or approving) does not
change.</li><li>Check the item in and move to the next task. For the authoring
task, this signifies that the authoring is complete. For subsequent
tasks, this signifies approval.</li><li>Check the item in and move to a previous task, indicating
rejection.</li>
</ol>
<p>This simple workflow is defined in
<kbd>sql/workflows/author-edit-publish.sql</kbd>.</p>
<h3>Workflow Creation</h3>
<p>Production of a content item frequently begins with a concept
which is initiated by the publisher and then executed by the staff.
In this scenario, the publisher creates the workflow and then
assigns each task in the workflow to one or more people. The API
calls to initialize a new workflow are as follows:</p>
<pre>
declare
  v_case_id integer;
  sample_object_id integer := 9;
  sample_user_id integer := 10;
begin

  v_case_id := workflow_case.new(  workflow_key =&gt; 'publishing_wf', 
                                   context_key =&gt; NULL, 
                                   object_id =&gt; sample_object_id);

  workflow_case.add_manual_assignment(v_case_id, 'authoring', sample_user_id);
  workflow_case.add_manual_assignment(v_case_id, 'editing', sample_user_id);
  workflow_case.add_manual_assignment(v_case_id,'approval', sample_user_id);

  workflow_case.start_case(case_id =&gt; v_case_id, msg =&gt; 'Here we go.');

end;
/
</pre>
<p>In this case, only one assignment is made per task. You can make
as many assignments per task as desired. There is currently no
workflow API to set deadlines, so you must write your own DML to
insert a row into <kbd>wf_case_deadlines</kbd> if you wish to allow
the publisher to set deadlines ahead of time.</p>
<p>The above workflow is created in the <strong>Default</strong>
context. In practice, you may wish to create one or more contexts
in which to create your workflows. Contexts may be used to
represent different departments within an organization.</p>
<p>The <kbd>start_case</kbd> enables the first task in the
workflow, in this case <strong>Authoring</strong>.</p>
<h3>Check Out Item</h3>
<p>If multiple persons are assigned to the same task, it is useful
to allow a single person to "check out" or lock an item
while they are working. This is accomplished with the following API
calls:</p>
<pre>
declare
  v_journal_id integer;
  sample_task_id := 1000;
  sample_user_id := 10;
  sample_ip := '127.0.0.1';
begin
  
  v_journal_id := workflow_case.begin_task_action(sample_task_id, 'start', 
    sample_ip, sample_user_id, 'Checking it out');
  workflow_case.end_task_action(v_journal_id, 'start', sample_task_id);

end;
/
</pre>
<p>A minimum of two calls are required to perform any action
related to a task. In this case we are simply notifying the
workflow engine that someone has started the task. You may specify
NULL for the journal message if the user does not wish to comment
on the check out.</p>
<h3>Check In Item</h3>
<p>Unless given a timeout period, a lock on a content item will
persist until the holding user checks the item back in. This
involves notifying the workflow engine that the user has finished
the task:</p>
<pre>
declare
  v_journal_id integer;
  sample_task_id integer := 1000;
  sample_user_id integer := 10;
  sample_ip := '127.0.0.1';
begin
  
  v_journal_id := workflow_case.begin_task_action(sample_task_id, 'finish', 
    sample_ip, sample_user_id, 'Done for now');
  workflow_case.set_attribute_value(v_journal_id, 'next_place', 'start');
  workflow_case.end_task_action(v_journal_id, 'finish', sample_task_id);

end;
/
</pre>
<p>Upon finishing a task, you must notify the workflow engine where
to go next. In this case, an author wishes to simply check an item
back in without actually completing the authoring task. The
<kbd>set_attribute_value</kbd> procedure must thus be used to set
<kbd>next_place</kbd> to the starting place of the workflow.</p>
<h3>Finish Task</h3>
<p>The process to finish a task varies slightly depending on
whether the user has previously checked out the item out or not. If
the user has not already checked it out (has been working on the
item without locking it, the code looks like this:</p>
<pre>
declare
  v_journal_id integer;
  sample_task_id integer := 1002;
  sample_user_id integer := 10;
  sample_ip := '127.0.0.1';
begin
  
  -- start the task
  v_journal_id := workflow_case.begin_task_action(sample_task_id, 'start', 
    sample_ip, sample_user_id, NULL);
  workflow_case.end_task_action(v_journal_id, 'start', sample_task_id);

  -- finish the task
  v_journal_id := workflow_case.begin_task_action(sample_task_id, 'finish', 
    sample_ip, sample_user_id, 'Authoring complete');
  workflow_case.set_attribute_value(v_journal_id, 'next_place', 'authored');
  workflow_case.end_task_action(v_journal_id, 'finish', sample_task_id);

end;
/
</pre>
<p>In this case an author is finishing the
<strong>Authoring</strong> task, upon which the workflow engine
will move the workflow to the <strong>Authored</strong> state (as
indicated by the <kbd>next_place</kbd> attribute). If the author
had previously checked out the item, then only the second step is
required.</p>
<h3>Approve or Reject</h3>
<p>Approval steps more commonly do not involve an explicit
check-out process. The code is thus virtually identical to that
above:</p>
<pre>
declare
  v_journal_id integer;
  sample_task_id integer := 1003;
  sample_user_id integer := 10;
  sample_ip := '127.0.0.1';
begin
  
  v_journal_id := workflow_case.begin_task_action(sample_task_id, 'start', 
    sample_ip, sample_user_id, NULL);
  workflow_case.end_task_action(v_journal_id, 'start', sample_task_id);

  v_journal_id := workflow_case.begin_task_action(sample_task_id, 'finish', 
    sample_ip, sample_user_id, 'Authoring complete');
  workflow_case.set_attribute_value(v_journal_id, 'next_place', 'edited');
  workflow_case.end_task_action(v_journal_id, 'finish', sample_task_id);

end;
/
</pre>
<p>Note the distinction between approval or rejection is determined
solely by the value of the <kbd>next_place</kbd> attribute.</p>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last Modified: <kbd>$&zwnj;Id: workflow.html,v 1.3 2018/03/27 11:17:59
hectorr Exp $</kbd>
