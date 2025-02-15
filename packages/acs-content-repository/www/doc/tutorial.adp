
<property name="context">{/doc/acs-content-repository/ {ACS Content Repository}} {ACS Content Repository Tutorial}</property>
<property name="doc(title)">ACS Content Repository Tutorial</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h2>How to use the content repository</h2>

by <a href="http://web.archive.org/web/20180809082906/http://www.rubick.com/">Jade
Rubick</a>
<h3>Why use the content repository?</h3>
<p>Let&#39;s say you&#39;re a developer making a package for
OpenACS. You&#39;ve heard statements like, "every package
should use the content repository", or maybe a developer has
suggested that you use it. Or maybe you just stumbled across it.
Why would you want to spend your time reading this document and
wasting a good afternoon when you could get started coding right
away?</p>
<p>The simple answer is that the content repository (CR) gives you
many different things for free:</p>
<ul>
<li>support for versioning</li><li>hierarchical organization of items</li><li>permissions</li><li>extending your tables dynamically</li>
</ul>

The content repository was created to solve many of the common
problems we as developers face.
<h3>State of this document</h3>

This is not a perfect introduction to the content repository. But
hopefully it will be a skeleton that can be developed further into
an excellent, helpful tutorial for people new to the content
repository.
<h3>Introduction</h3>
<p>For the sake of an example, I&#39;m going to use a Tasks
application. This application will keep track of all the tasks of
an organization, deadlines for those tasks, and who needs to work
on them.</p>
<p>The reason I might be interested in using the content repository
(CR) in this case is that I can keep track of all the changes to a
particular Task, so that if someone changes the deadline on an
item, I can see what the original deadline was. In addition, I as a
developer would like to have sub-tasks, and sub-sub-tasks, so I can
have a whole hierarchy of things that need to be accomplished. Big
tasks can be sub-divided so that several people can each do their
particular parts.</p>
<p>So I decide to create a Tasks table. Each of these Tasks has
various information associated with it, such as deadlines,
descriptions of what needs to be accomplished, and so on:</p>
<blockquote><pre>
<strong>Task</strong>
          Title
          Description
          Task Number
        </pre></blockquote>
<h3>Overview</h3>
<p>First of all, let&#39;s get some terminology out of the way.
Columns of a table are referred to as <em>attributes</em> in
content repository-speak.</p>

The steps to set up your data model are as follows:
<ol>
<li>What attributes do you want?</li><li>Define tables</li><li>Describe attributes</li>
</ol>
<h3>What attributes do you want?</h3>
<p>The first step is to decide on what part of a Task you&#39;d
you&#39;d like to have under revision control, and what portion
you&#39;d like to have just one version of. In our case, the only
thing we wouldn&#39;t want under version control is the Task
Number. This will be a unique identifier for the task, and we
don&#39;t want that changing every time someone edits it.</p>
<p>For our simple example:</p>
<blockquote><pre>
          Title - want versions
          Description - want versions
          Task Number - do NOT want versions
        </pre></blockquote>
<h3>Define tables</h3>
<p>You will have two tables: one with versioned attributes, and one
without versioned attributes.</p>
<p>
<em>Convention:</em> often, developers will name the first table
by what it is (in my case <strong>pm_tasks</strong>), and the
second, versioned table by the same name, but with _revisions at
the end. Thus, I&#39;ll name my second table
<strong>pm_tasks_revisions</strong>.</p>

This is actually very easy:
<p>Versioned portion:</p>
<blockquote><pre>
            create table pm_tasks_revisions (
            task_revision_id
            integer 
            constraint pm_tasks_revisions_id_pk
            primary key
            constraint pm_tasks_revisions_id_fk
            references <strong>cr_revisions</strong>(revision_id)
            on delete cascade,
            title
            varchar(100),
            description
            varchar(4000)
            );
          </pre></blockquote>
<p>Unversioned portion:</p>
<blockquote><pre>
            create table pm_tasks (
            task_id
            integer
            constraint pm_tasks_id_pk
            primary key
            constraint pm_tasks_id_fk
            references <strong>cr_items</strong>(item_id)
            on delete cascade,
            task_number
            integer
            )
          </pre></blockquote>
<p>One thing you have to be careful of when creating these tables
is that there are no columns that have the same names as any of the
columns in the <code>cr_items</code> and <code>cr_revisions</code>
tables. For example, you can&#39;t call you key on the
pm_tasks_revisions table <code>revision_id</code>. Why? There are
some views that are automatically generated that combine these
tables for you, but they won&#39;t be created if the names
conflict. I&#39;ll describe what these views are later, but they
are useful. You were warned.</p>
<p>Notice that each table uses as its primary key a reference to
either the <code>cr_revisions</code> table or the
<code>cr_items</code> table. A <em>content item</em> is basically
just some content: either text or binary data. The <em>contents
revisions</em> table keeps track of which version from the
tasks_revisions table is the most current, and which one is
live.</p>
<p>All this is going inside the
<code>sql/postgresql/project-manager-create.sql</code> file. Your
name will be different of course.</p>
<h3>Describe attributes</h3>
<p>After we&#39;ve created the two tables, we need to let the
content repository know that we have a new type of structured data
that we are storing in the content repository. Tasks are a
"content type", because they have data associated with
them, such as when they are due, and what needs to be done.</p>
<p>I thus need to</p>
<blockquote><pre>
          --create the content type
          select content_type__create_type (
          'pm_task', -- content_type   
          'content_revision', -- not sure what this is
          'Task', -- pretty_name
          'Tasks', -- pretty_plural
          'pm_tasks_revisions', -- table name
          'task_id', -- id_column
          'content_revision.revision_name'
          );
        </pre></blockquote>
<p>You then need to add in all the attributes, so that the content
repository can do some magic things behind the scenes. The content
repository doesn&#39;t know about what&#39;s inside of the
<em>pm_tasks</em> and <em>pm_tasks_revisions</em> tables, so we
teach it:</p>
<blockquote><pre>
          -- add in attributes
          
          select content_type__create_attribute (
          'pm_task', -- content_type
          'start_date', -- attribute_name
          'date',     -- datatype (string, number, boolean, date, keyword, integer)
          'Start date', -- pretty_name
          'Start dates', -- pretty_plural
          null, -- sort_order
          null, -- default value
          'timestamptz' -- column_spec
          );
          
          select content_type__create_attribute (
          'pm_task', -- content_type
          'end_date', -- attribute_name
          'date',     -- datatype
          'End date', -- pretty_name
          'End dates', -- pretty_plural
          null, -- sort_order
          null, -- default value
          'timestamptz' -- column_spec
          );
          
          select content_type__create_attribute (
          'pm_task', -- content_type
          'percent_complete', -- attribute_name
          'number',           -- datatype
          'Percent complete', -- pretty_name
          'Percents complete', -- pretty_plural
          null, -- sort_order
          null, -- default value
          'numeric' -- column_spec
          );
        </pre></blockquote>
<p>
<strong>Side effect</strong>: once you&#39;ve created the
content type, the content repository creates a view for you called
<code>pm_tasks_revisionsx</code>. Note the x at the end of the
name. If you&#39;re using Postgres, I believe it will also create a
view for you called <code>pm_tasks_revisionsi</code>
</p>
<p>Why are these two views created? the x view is created for
selection, and the i view is created for inserts. They join the
acs_objects, cr_revisions, and our pm_tasks_revisions tables
together. Try viewing them to get an idea of how they might be
useful.</p>
<h3>Advanced topic: Creating types and attributes</h3>
<p>It is also possible to dynamically create tables, and extend
them with extra columns. You could do this by using <code>create
table</code> or <code>alter table add column</code> statements in
SQL, but this also adds in some meta-data that will be useful to
you. The disadvantage is that you have to call the content
repository API. The advantage is that someday you&#39;ll be able to
do really cool stuff with it, like automatically generate
interfaces that take advantage of the new columns and tables
you&#39;ve added. Another nice thing is that all that messy
business of defining your attributes through the API is taken care
of.</p>
<p>
<em>Types</em> is the content repository are another term for
tables, although that doesn&#39;t explain it completely. Types are
also kept track of within OpenACS, in the
<code>acs_object_types</code> table, so the system knows about the
tables you create, and can do some intelligent things with
them.</p>
<p>A lot of the <em>intelligent things</em> you can do with this
information is still being built. But imagine for example that you
are using the project manager package I&#39;ve written. You work at
an ice cream company, and every task that is done also has an
associated ice cream flavor with it (yeah, this isn&#39;t a good
example, but pay attention anyway). If I&#39;ve written the project
manager to take advantage of it, when you add in this extra
attribute to the pm_tasks_revisions table, the UI aspects will be
automatically taken care of. You&#39;ll be able to select a flavor
when you edit a task, and it will be shown on the task view page.
This is the direction OpenACS development is going, and it will be
really really cool!</p>
<p>First, I&#39;m going to describe how to extend other content
repository tables using the CR API. Then, I&#39;ll describe how to
set up your own tables as well:</p>
<p>As you recall from earlier in this page, attributes are just
another term for columns in a table. The Content Repository has a
mechanism for adding and removing columns via the pl/sql API. If
you check your /api-doc:
<code>/api-doc/plsql-subprogram-one?type=FUNCTION&amp;name=content%5ftype%5f%5fcreate%5fattribute</code>
, you&#39;ll see that there is a way to extend the columns
programmatically.</p>
<p>Why would you want to do this? For project manager, I decided to
do this because I wanted to customize my local version of the
projects table, to account for company-specific information. That
way, I can have a separate edit page for those types, but not have
a separate table to join against.</p>

. Instead of doing this:
<blockquote><pre>
alter table pm_projects add column 
        target_date  date;
</pre></blockquote>

I can do this:
<blockquote><pre>
select content_type__create_attribute(
        'pm_project',
        'target_date',
        'date',
        'Target date',
        'Target dates',
        null,
        null,
        'date'
);
</pre></blockquote>

A very important advantage of this method is that it recreates all
the views associated with the pm_projects table, like pm_projectsx.
If I did an alter table statement, all the views would not contain
the new column. Note that I believe you CAN create foreign key
constraints, by putting them in the column spec (the last column):
<blockquote><pre>
select content_type__create_attribute(
        'pm_project',
        'company_id',
        'integer',
        'Company',
        'Companies',
        null,
        null,
        'integer constraint pm_project_comp_fk references organizations'
);</pre></blockquote>

I have no idea of whether or not that is supposed to be legal, but
I believe it works. Jun was the one who originally talked about
<a href="http://openacs.org/forums/message-view?message_id=112355">the
possibility of storing all the revisioned columns in a generic
table</a>
.
<h3>How versioning works</h3>

You then need to define a couple of functions, that do all the
nasty work of putting everything in the right tables. The general
idea behind it is that the revisioned information is never changed,
but added to. Here&#39;s how it works. When you create a new task,
you call the <code>pm_task__new_task_item</code>
 function (which
we&#39;ll write in a little bit). This function creates both a new
content item, and a new content revision. Information is actually
stored in four tables, believe it or not:
<code>cr_revisions</code>
, <code>cr_items</code>
,
<code>pm_tasks</code>
, and <code>pm_tasks_revisions</code>
. The
task number is stored in pm_tasks, the title and description are
stored in pm_tasks_revisions, and some additional information like
who entered the information is stored in cr_revisions and cr_items.
Whenever you make a change to this item, you don&#39;t change the
table yourself, but <strong>add</strong>
 a revision, using your
<code>pm_task__new_task_revision</code>
 function (which we&#39;ll
write in a little bit). This function adds another revision, but
<em>not</em>
 another item or cr_item. After you&#39;ve added
another revision, you&#39;ll have two revisions and one item. Two
entries in cr_revisions (and pm_tasks_revisions), and one item in
cr_items and pm_tasks. The cr_revisions table keeps track of which
item is the most recent, and which item is "live". For
the edit-this-page application, for example, this is used to keep
track of which revision to a page is actually being served to
users. In your code, you&#39;ll use your pm_tasks_revisionsx view,
which joins the pm_tasks_revisions table with the cr_revisions
table (and it might even join in cr_items -- I forget at the
moment).
<h3>Defining your pl/sql functions</h3>

You can see the actual functions used in project manager via the
<a href="https://github.com/openacs/project-manager/tree/master/sql/postgresql/">
GitHub browser&#39;s entry for project-manager</a>
. Note these are
a little more expanded than what I&#39;ve used in the examples
above.
<blockquote><pre>
select define_function_args('pm_task__new_task_item', 'task_id, project_id, title, description, end_date, percent_complete, estimated_hours_work, estimated_hours_work_min, estimated_hours_work_max, creation_date, creation_user, creation_ip, package_id');

create function pm_task__new_task_item (
        p_task_id integer,
        p_project_id integer,
        p_title varchar,
        p_description varchar,
        p_end_date timestamptz,
        p_percent_complete numeric,
        p_estimated_hours_work numeric,
        p_estimated_hours_work_min numeric,
        p_estimated_hours_work_max numeric,
        p_creation_date timestamptz,
        p_creation_user integer,
        p_creation_ip varchar,     
        p_package_id integer       
) returns integer 
as $$
declare
        v_item_id               cr_items.item_id%TYPE;
        v_revision_id           cr_revisions.revision_id%TYPE;
        v_id                    cr_items.item_id%TYPE;
        v_task_number           integer;
begin
        select acs_object_id_seq.nextval into v_id from dual;

        -- We want to put the task under the project item

        -- create the task_number
        
        v_item_id := content_item__new (
                v_id::varchar,          -- name
                p_project_id,           -- parent_id
                v_id,                   -- item_id
                null,                   -- locale
                now(),                  -- creation_date
                p_creation_user,        -- creation_user
                p_package_id,           -- context_id
                p_creation_ip,          -- creation_ip
                'content_item',         -- item_subtype
                'pm_task',              -- content_type
                p_title,                -- title
                p_description,          -- description
                'text/plain',           -- mime_type
                null,                   -- nls_language
                null                    -- data
        );

        v_revision_id := content_revision__new (
                p_title,                -- title
                p_description,          -- description
                now(),                  -- publish_date
                'text/plain',           -- mime_type
                NULL,                   -- nls_language
                NULL,                   -- data
                v_item_id,              -- item_id
                NULL,                   -- revision_id
                now(),                  -- creation_date
                p_creation_user,        -- creation_user
                p_creation_ip           -- creation_ip
        );

        PERFORM content_item__set_live_revision (v_revision_id);

        insert into pm_tasks (
                task_id, task_number)
        values (
                v_item_id, v_task_number);

        insert into pm_tasks_revisions (
                task_revision_id, end_date, percent_complete, estimated_hours_work, estimated_hours_work_min, estimated_hours_work_max, actual_hours_worked)
        values (
                v_revision_id, p_end_date, p_percent_complete, p_estimated_hours_work, p_estimated_hours_work_min, p_estimated_hours_work_max, '0');

        PERFORM acs_permission__grant_permission(
                v_revision_id,
                p_creation_user,
                'admin'
        );

        return v_revision_id;
end;
$$ language plpgsql;


select define_function_args('pm_task__new_task_revision', 'task_id, project_id, title, description, end_date, percent_complete, estimated_hours_work, estimated_hours_work_min, estimated_hours_work_max, actual_hours_worked, creation_date, creation_user, creation_ip, package_id');

create function pm_task__new_task_revision (
        p_task_id integer,     -- the item_id
        p_project_id integer,
        p_title varchar,
        p_description varchar,
        p_end_date timestamptz,
        p_percent_complete numeric,
        p_estimated_hours_work numeric,
        p_estimated_hours_work_min numeric,
        p_estimated_hours_work_max numeric,
        p_actual_hours_worked numeric,
        p_creation_date timestamptz,
        p_creation_user integer,
        p_creation_ip varchar,
        p_package_id integer
) returns integer 
as $$
declare
        v_revision_id           cr_revisions.revision_id%TYPE;
        v_id                    cr_items.item_id%TYPE;
begin
        select acs_object_id_seq.nextval into v_id from dual;

        -- We want to put the task under the project item

        v_revision_id := content_revision__new (
                p_title,                -- title
                p_description,          -- description
                now(),                  -- publish_date
                'text/plain',           -- mime_type
                NULL,                   -- nls_language
                NULL,                   -- data
                p_task_id,              -- item_id
                NULL,                   -- revision_id
                now(),                  -- creation_date
                p_creation_user,        -- creation_user
                p_creation_ip           -- creation_ip
        );

        PERFORM content_item__set_live_revision (v_revision_id);

        insert into pm_tasks_revisions (
                task_revision_id, end_date, percent_complete, estimated_hours_work, estimated_hours_work_min, estimated_hours_work_max, actual_hours_worked)
        values (
                v_revision_id, p_end_date, p_percent_complete, p_estimated_hours_work, p_estimated_hours_work_min, p_estimated_hours_work_max, p_actual_hours_worked);

        PERFORM acs_permission__grant_permission(
                v_revision_id,
                p_creation_user,
                'admin'
        );

        return v_revision_id;
end;
$$ language plpgsql;


-- The delete function deletes a record and all related overhead. 

select define_function_args('pm_task__delete_task_item', 'task_id');

create or replace function pm_task__delete_task_item (p_task_id integer)
returns integer as $$
declare
begin
        delete from pm_tasks_revisions
                where task_revision_id in (select revision_id from pm_tasks_revisionsx where item_id = p_task_id);

        delete from pm_tasks
                where task_id = p_task_id;

        raise NOTICE 'Deleting pm_task...';

        PERFORM content_item__delete(p_task_id);
        return 0;
end;
$$ language plpgsql;
</pre></blockquote>
<h3>Explanation of the columns in cr_items and cr_revisions</h3>

cr_items:
<blockquote>
<strong>item_id</strong> - unique id for this item,
will be different than the revision_id<br><strong>parent_id</strong> - used to group items into a hierarchy
(see below)<br><strong>name</strong> - this is used to make a URL by the content
repository. It must be unique per content folder. You can use a
number, or something like project_231. One way to do this is to set
it equal to a title plus the item_id.<br><strong>locale</strong> - not sure, probably for
internationalization support<br><strong>live_revision</strong> - this is equal to the cr_revision
table&#39;s revision_id that is the live version<br><strong>latest_revision</strong> - this is equal to the cr_revision
table&#39;s revision_id that is the latest version<br><strong>publish_status</strong> - not sure<br><strong>content_type</strong> - not sure<br><strong>storage_type</strong> - not sure, probably text or
binary?<br><strong>storage_area_key</strong> - not sure<br><strong>tree_sortkey</strong> - a utility column used in
hierarchical queries.<br>
</blockquote>

cr_revisions:
<blockquote>
<strong>revision_id</strong> - a unique id for this
revision.<br><strong>item_id</strong> - a reference to the item_id for this
revision<br><strong>title</strong> - you can use this for your application. For
example, My Big Project<br><strong>description</strong> - you can use this for your
application, as a longer description.<br><strong>publish_date</strong> - the date this was published. Not
sure if this is for your use, or internal<br><strong>mime_type</strong> - the mime type.<br><strong>nls_language</strong> - I believe this is for
internationalization<br><strong>lob</strong> - the binary content.<br><strong>content</strong> - the text content.<br><strong>content_length</strong> - the length of the text or binary
content?<br>
</blockquote>
<h3>Structuring your data into a hierarchy</h3>

The content repository also has a very useful facility for
organizing your data into a hierarchy, very similar to a
file-system. Just like a filesystem, you can have folders to store
items inside of, and organize your information. The main difference
is that every item can also contain other items. So in our case, we
can have tasks that contain other tasks. This is a useful way for
us to specify sub-tasks, and sub-sub-tasks. In my case, building
project-management software, this also allows my tasks to be stored
underneath their given project.
<p>Using this structure is optional, but useful in many
circumstances.</p>
<p>The facility for this is built into the <code>cr_items</code>
data model. This makes sense, because you wouldn&#39;t want your
hierarchy associated with each revision. Here&#39;s how Postgres
describes the <code>cr_items</code> table:</p>
<blockquote><pre>
                         Table "public.cr_items"
      Column      |          Type          |          Modifiers          
------------------+------------------------+-----------------------------
 item_id          | integer                | not null
 <strong>parent_id</strong>        | integer                | not null
 name             | character varying(400) | not null
 locale           | character varying(4)   | 
 live_revision    | integer                | 
 latest_revision  | integer                | 
 publish_status   | character varying(40)  | 
 content_type     | character varying(100) | 
 storage_type     | character varying(10)  | not null default 'text'
 storage_area_key | character varying(100) | not null default 'CR_FILES'
 tree_sortkey     | bit varying            | 
</pre></blockquote>

The <code>parent_id</code>
 refers to either a content item
(<code>cr_items</code>
), or a subclass of a content_item (such as
<code>cr_folders</code>
). I&#39;ll explain more later about
<code>cr_folders</code>
.
<p>One thing that you might want to do for your application is to
give the application its own root directory. Because the content
repository is shared among applications, this separates it off from
other applications. They can still use the items in your
application, but it must be a more deliberate process. If you
don&#39;t create your own root directory, you may see
strange-looking data from other applications in your application,
or see your application&#39;s data in other applications. There are
times when you&#39;ll want to do this, but probably not until
you&#39;re much more familiar with the content repository. Another
reason for creating your own root repository is that you
application may be mounted several times. If you want to separate
the directory structure between instances of your application, you
need to create your own root directory:</p>
<blockquote><pre>
-- Creates and returns a unique name for new project folders

select define_function_args('pm_project__new_unique_name', 'package_id');

create function pm_project__new_unique_name (p_package_id integer)
returns text as $$
declare
        v_name                  cr_items.name%TYPE;
        v_package_key           apm_packages.package_key%TYPE;
        v_id                    integer;
begin
        select package_key into v_package_key from apm_packages
            where package_id = p_package_id;

        select acs_object_id_seq.nextval into v_id from dual;

        -- Set the name
        select v_package_key || '_' || 
            to_char(current_timestamp, 'YYYYMMDD') || '_' ||
            v_id into v_name;

        return v_name;
end;
$$ language plpgsql;


select define_function_args('pm_project__new_root_folder', 'package_id');

create function pm_project__new_root_folder (p_package_id integer)
returns integer as $$
declare
        v_folder_id                cr_folders.folder_id%TYPE;
        v_folder_name           cr_items.name%TYPE;
begin
        -- Set the folder name
        v_folder_name := pm_project__new_unique_name (p_package_id);

        v_folder_id := content_folder__new (
            v_folder_name,              -- name
            'Projects',                 -- label
            'Project Repository',       -- description
            p_package_id                -- parent_id
        );

        -- Register the standard content types
        PERFORM content_folder__register_content_type (
            v_folder_id,         -- folder_id
            'pm_project',        -- content_type
            'f'                  -- include_subtypes
        );

        -- TODO: Handle Permissions here for this folder.

        return v_folder_id;
end;
$$ language plpgsql;
</pre></blockquote>

Note that this example is for projects rather than tasks. This is
because for the application I&#39;m writing, projects are what
tasks are stored inside of. A project has many component tasks. If
you were writing another application, or if I was not doing
anything with projects, then this would be creating a folder for
just tasks.
<p>Typically, this definition would go in your
<code>sql/postgresql/project-manager-create.sql</code> file. If
this file is broken in several parts, this would go in the
project-manager-create-functions.sql portion.</p>
<p>Once you&#39;ve created your root directory, you will set the
<code>parent_id</code> of your items to the id for the new root
repository (in our case, it&#39;s returned from the
<code>pm_project__new_root_folder function</code>)</p>
<p>In the project-manager application, we&#39;ll create a root
repository, and make all projects under that root repository. That
means they&#39;ll all have a <code>parent_id</code> set to the root
repository. However, we also want to make projects that are
sub-projects of other projects. In that case, we will set the
<code>parent_id</code> of the sub-project to the
<code>item_id</code> of the parent.</p>
<h4>Understanding folders</h4>

For a little while now, we have been talking about folders, but we
haven&#39;t delved into what CR folders are. Folders are
sub-classes of <code>cr_items</code>
, and the only real difference
is that they contain no data, except for a label and description.
<p>If you create folders for your application, then you&#39;ll need
to make sure you manage them along with your other objects. For
example, if you were to add a folder for each of your objects, then
you would probably want to make sure you delete the folder when you
delete the object.</p>
<p>However, in many cases you are not creating more than one
folder. In fact, the only folder you might have will be the root
folder you create for each instance of your application (if you
install the project-manager in two parts of your web server, for
example, it should have two different root folders). When your
application is running, it can determine the root folder by
searching the cr_folders table. Here&#39;s the definition of that
table:</p>
<blockquote><pre>
                 Table "public.cr_folders"
       Column       |          Type           |  Modifiers  
--------------------+-------------------------+-------------
 folder_id          | integer                 | not null
 label              | character varying(1000) | 
 description        | text                    | 
 has_child_folders  | boolean                 | default 'f'
 has_child_symlinks | boolean                 | default 'f'
 <strong>package_id</strong>         | integer                 | 
</pre></blockquote>

Note that there is a <code>package_id</code>
 column. The nice thing
about this column is that you can use it to find the root
repository, if you only have one folder per instance of your
application. You can get your package_id using this call within
your .tcl file:
<blockquote><pre>
set package_id [ad_conn package_id]
</pre></blockquote>

Then you can find the root repository by using a query like this:
<blockquote><pre>
select folder_id from cr_folders where package_id = :package_id;
</pre></blockquote>
<h3>Create scripts</h3>
<h3>Drop scripts</h3>

If you have problems with your drop script in OpenACS 4.6.2, then
<a href="http://openacs.org/forums/message-view?message_id=112355">Tammy&#39;s
drop scripts</a>
 might be of interest to you.
<h2>Using your data model</h2>

You now have a shiny new data model that handles revisions and all
sorts of other things we haven&#39;t gotten to yet. Now, in your
Tcl pages and your ps/sql code, you can...
<table border="1" cellpadding="1" cellspacing="0">
<tr>
<th>Get latest revision (Tcl)</th><td>set live_revision_id [db_exec_plsql get_live_revision {select
content_item__get_live_revision(:item_id)}]</td>
</tr><tr>
<th>Get latest revision (pl/sql)</th><td>live_revision_id :=
content_item__get_live_revision(:item_id);</td>
</tr>
</table>
<p>The item_id identifies the content item with which the revision
is associated.</p>
<p>Likewise, the most recent revision of a content item can be
obtained with the content_item__get_latest_revision function</p>
<h3>Reference:</h3>
<ul>
<li><a href="http://openacs.org/doc/acs-content-repository/">OpenACS Content
Repository docs</a></li><li><a href="http://www.thedesignexperience.org/openacs-stuff/contentrepository">
Dave&#39;s page on Using the Content Repository</a></li>
</ul>
<h3>Reference: Definitions</h3>
<dl>
<dt>Content Type</dt><dd>A set of attributes that may be associated with a text or
binary content object. For example, a press_release content type
may include a title, byline, and publication date. These attributes
are stored in the <code>cr_revisions</code> table, and a table that
you set up to store specialized data. In this case, the title (I
think), byline, and publication date would be stored in a
specialized table.</dd>
</dl>
<dl>
<dt>Content Item</dt><dd>Items are the fundamental building blocks of the content
repository. Each item represents a distinct text or binary content
object that is publishable to the web, such as an article, report,
message or photograph. An item my also include any number of
attributes with more structured data, such as title, source, byline
and publication date.</dd>
</dl>
<dl>
<dt>Content Revision</dt><dd>A revision consists of the complete state of the item as it
existed at a certain point in time. This includes the main text or
binary object associated with the item, as well as all
attributes.</dd>
</dl>
<dl>
<dt>Content Folder</dt><dd>A folder is analogous to a folder or directory in a filesystem.
It represents a level in the content item hierarchy. In the
previous example, press-releases is a folder under the repository
root, and products is folder within that.</dd>
</dl>
<dl>
<dt>Symbolic Link</dt><dd>Analogous to a symlink, alias or shortcut in a filesystem.
Allows an item to be accessed from multiple folders.</dd>
</dl>
<dl>
<dt>Templates</dt><dd>Templates are merged with content items to render output in
HTML or other formats. Templates are assumed to be text files
containing static markup with embedded tags or code to incorporate
dynamic content in appropriate places.</dd>
</dl>
<h3>Content templates</h3>

The only place content templates are used in OpenACS are in the 5.0
version of file storage. See <a href="http://openacs.org/forums/message-view?message_id=134773">CR and
content_template defined wrong</a>
<h3>Troubleshooting</h3>

One problem I ran into while trying to get my SQL create and drop
scripts working was that sometimes I was not able to delete a
content type because I would get errors like these:
<blockquote><pre>
Referential Integrity: attempting to delete live_revision: 658
</pre></blockquote>

The problem seems to be that there were still items in the
<code>cr_items</code>
 table. You can remove them using <code>select
content_item__delete(648);</code>
 in psql. You get the codes by
doing a query like this:
<blockquote><pre>
select i.item_id, r.revision_id, r.title, i.content_type from cr_items i, cr_revisions r where i.item_id = r.item_id order by i.item_id, r.revision_id;
</pre></blockquote>

Really, however, what you need to do is make sure your __delete and
drop scripts first go through and delete all children of those
items. I&#39;m not sure if you need to delete the items themselves
-- I believe they may be dropped by themselves when the tables are
dropped, because of the <code>cascade</code>
 portion of the SQL
data model.
<p>When I was troubleshooting folders, I found this query
useful:</p>
<blockquote><pre>
select f.folder_id,f.label,f.description,i.content_type from cr_folders f, cr_items i where f.folder_id = i.item_id;
</pre></blockquote>
<p>Once again, thanks to daveb for help in tracking this down (he
rocks!).</p>
