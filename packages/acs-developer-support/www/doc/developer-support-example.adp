
<property name="context">{/doc/acs-developer-support {ACS Developer Support}} {Request Information}</property>
<property name="doc(title)">Request Information</property>
<master>
<h2>Request Information</h2>
<a href="/pvt/home">Your Workspace</a>
 : <a href="/admin/">Admin
Home</a>
 : <a href="/ds">Developer Support</a>
 : Request
Information
<h3>Parameters</h3>
<blockquote><table cellspacing="0" cellpadding="0">
<tr>
<th align="left">Request Start Time: </th><td>Thu Jun 01 10:49:16 2000 (959870956)</td>
</tr><tr valign="top">
<th align="left" nowrap="nowrap">Request Completion Time: </th><td>Thu Jun 01 10:49:20 2000 (959870960)</td>
</tr><tr valign="top">
<th align="left" nowrap="nowrap">Request Duration: </th><td>4077 ms</td>
</tr><tr valign="top">
<th align="left" nowrap="nowrap">Method: </th><td>GET</td>
</tr><tr valign="top">
<th align="left" nowrap="nowrap">URL: </th><td>/intranet/ad-index</td>
</tr><tr valign="top">
<th align="left" nowrap="nowrap">Query: </th><td>(empty)</td>
</tr>
</table></blockquote>
<h3>Headers</h3>
<blockquote><table cellspacing="0" cellpadding="0">
<tr valign="top">
<th align="left">Connection: </th><td>Keep-Alive</td>
</tr><tr valign="top">
<th align="left">User-Agent: </th><td>Mozilla/4.61 [en] (X11; U; Linux 2.2.12-20 i686)</td>
</tr><tr valign="top">
<th align="left">Host: </th><td>dev.arsdigita.com</td>
</tr><tr valign="top">
<th align="left">Accept: </th><td>image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png,
*/*</td>
</tr><tr valign="top">
<th align="left">Accept-Encoding: </th><td>gzip</td>
</tr><tr valign="top">
<th align="left">Accept-Language: </th><td>en</td>
</tr><tr valign="top">
<th align="left">Accept-Charset: </th><td>iso-8859-1,*,utf-8</td>
</tr><tr valign="top">
<th align="left">Cookie: </th><td>last_visit=959374634; ad_browser_id=4608;
second_to_last_visit=959269200;
ad_user_login=1472%2cISotUu64GyYZUPdBdNVRWMsdVnRaFzwG;
ad_session_id=198622%2c1472%2cjbJ4dmbI8QQd5nSSobE%2e9c5H%2fQyOVs1v%2c959870956</td>
</tr>
</table></blockquote>
<h3>Output Headers</h3>
<blockquote><table cellspacing="0" cellpadding="0">
<tr valign="top">
<th align="left">Set-Cookie: </th><td>last_visit=959870956; path=/; expires=Fri, 01-Jan-2010 01:00:00
GMT</td>
</tr><tr valign="top">
<th align="left">Set-Cookie: </th><td>second_to_last_visit=959374634; path=/; expires=Fri,
01-Jan-2010 01:00:00 GMT</td>
</tr><tr valign="top">
<th align="left">MIME-Version: </th><td>1.0</td>
</tr><tr valign="top">
<th align="left">Date: </th><td>Thu, 01 Jun 2000 14:49:20 GMT</td>
</tr><tr valign="top">
<th align="left">Server: </th><td>AOLserver/3.0+ad2</td>
</tr><tr valign="top">
<th align="left">Content-Type: </th><td>text/html</td>
</tr><tr valign="top">
<th align="left">Content-Length: </th><td>10715</td>
</tr><tr valign="top">
<th align="left">Connection: </th><td>close</td>
</tr>
</table></blockquote>
<h3>Database Requests</h3>
<blockquote><table cellspacing="0" cellpadding="0">
<tr>
<th bgcolor="black"><font color="white">  Duration  </font></th><th bgcolor="black"><font color="white">Command</font></th>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">gethandle -timeout -1 (returned nsdb0)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  13 ms  </td><td bgcolor="#FFFFFF">dml nsdb0 (main pool)
<blockquote><pre>update session_statistics 
set session_count = session_count + 1, 
repeat_count = repeat_count + 1 
where entry_date = trunc(sysdate)</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  124 ms  </td><td bgcolor="#DDDDDD">dml nsdb0 (main pool)
<blockquote><pre>update users
set last_visit = sysdate,
    second_to_last_visit = last_visit,
    n_sessions = n_sessions + 1
where user_id = 1472</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">releasehandle nsdb0 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">gethandle (returned nsdb1)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  6 ms  </td><td bgcolor="#FFFFFF">1row nsdb1 (main pool)
<blockquote><pre>select decode(count(1),0,0,1) 
               from user_group_map 
              where user_id=1472 
                and (group_id=6
                     or group_id=1181)</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">releasehandle nsdb1 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">gethandle (returned nsdb2)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  10 ms  </td><td bgcolor="#DDDDDD">0or1row nsdb2 (main pool)
<blockquote><pre>select group_id 
from administration_info 
where module = 'intranet' 
and submodule is null</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  13 ms  </td><td bgcolor="#FFFFFF">1row nsdb2 (main pool)
<blockquote><pre>
select count(*) from user_group_map where user_id =1472 and group_id = 2</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  9 ms  </td><td bgcolor="#DDDDDD">0or1row nsdb2 (main pool)
<blockquote><pre>select group_id 
from administration_info 
where module = 'site_wide' 
and submodule is null</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  12 ms  </td><td bgcolor="#FFFFFF">1row nsdb2 (main pool)
<blockquote><pre>
select multi_role_p from user_groups where group_id = 1</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  17 ms  </td><td bgcolor="#DDDDDD">1row nsdb2 (main pool)
<blockquote><pre>
select decode(count(*), 0, 0, 1) from user_group_map where user_id = 1472 and group_id = 1 and role in ('administrator', 'all')</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  18 ms  </td><td bgcolor="#FFFFFF">0or1row nsdb2 (main pool)
<blockquote><pre>select first_names || ' ' || last_name as full_name, 
                decode(portrait_upload_date,NULL,0,1) as portrait_exists_p
           from users 
          where user_id=1472</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1225 ms  </td><td bgcolor="#DDDDDD">select nsdb2 (main pool)
<blockquote><pre>select ug.group_name, ug.group_id
           from user_groups ug, im_projects p
          where ad_group_member_p ( 1472, ug.group_id ) = 't'
            and ug.group_id=p.group_id
            and p.project_status_id in (select project_status_id
                                          from im_project_status 
                                         where project_status='Open' 
                                            or project_status='Future' )
          order by lower(group_name)</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t39 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  2 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t39 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t39 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t39 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t39 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  2 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t39 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1578 ms  </td><td bgcolor="#FFFFFF">select nsdb2 (main pool)
<blockquote><pre>select ug.group_name, ug.group_id
           from user_groups ug, im_customers c
          where ad_group_member_p ( 1472, ug.group_id ) = 't'
            and ug.group_id=c.group_id
            and c.customer_status_id in (select customer_status_id 
                                          from im_customer_status 
                                         where customer_status in ('Current','Inquiries','Creating Bid','Bid out'))
          order by lower(group_name)</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  2 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t54 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  30 ms  </td><td bgcolor="#FFFFFF">1row nsdb2 (main pool)
<blockquote><pre>select sum(hours) from im_hours where user_id=1472
    and on_which_table='im_projects'
    and day &gt;= sysdate - 7</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  14 ms  </td><td bgcolor="#DDDDDD">1row nsdb2 (main pool)
<blockquote><pre>select decode(count(1),0,0,1) 
           from user_groups ug
          where ad_group_member_p ( 1472, ug.group_id ) = 't'
            and ug.short_name='Business'</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  15 ms  </td><td bgcolor="#FFFFFF">1row nsdb2 (main pool)
<blockquote><pre>select decode(count(1),0,0,1) 
           from user_groups ug
          where ad_group_member_p ( 1472, ug.group_id ) = 't'
            and ug.short_name='Finance'</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  5 ms  </td><td bgcolor="#DDDDDD">1row nsdb2 (main pool)
<blockquote><pre>select sysdate - 30 from dual</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  4 ms  </td><td bgcolor="#FFFFFF">select nsdb2 (main pool)
<blockquote><pre>
select newsgroup_id from newsgroups where scope = 'all_users' or scope = 'registered_users' or (scope = 'group' and group_id = 6)</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t71 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t71 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t71 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t71 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  16 ms  </td><td bgcolor="#DDDDDD">select nsdb2 (main pool)
<blockquote><pre>select news.title, news.news_item_id, news.approval_state, 
 expired_p(news.expiration_date) as expired_p, 
 to_char(news.release_date,'Mon DD, YYYY') as release_date_pretty
from news_items news, users ut
where creation_date &gt; '2000-05-02'
and (newsgroup_id = 1 or newsgroup_id = 2 or newsgroup_id = 4)
and news.approval_state = 'approved'
and release_date &lt; sysdate
and news.creation_user = ut.user_id
order by release_date desc, creation_date desc</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t82 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  2 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t82 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t82 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  2 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t82 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t82 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  137 ms  </td><td bgcolor="#DDDDDD">select nsdb2 (main pool)
<blockquote><pre>select g.group_name, g.group_id
               from user_groups g, im_projects p, im_employees_active u, im_project_types
              where p.project_lead_id = u.user_id
                and p.project_type_id = im_project_types.project_type_id
                and p.group_id=g.group_id
                and p.requires_report_p='t'
         and u.user_id='1472'
         and p.project_status_id = (select project_status_id 
                                               from im_project_status
                                              where project_status='Open')
         and ( (lower(project_type) not in ('client - full service')
               and not exists  (select 1 
                                  from general_comments gc
                                 where gc.comment_date &gt; sysdate - 7
                                   and on_which_table = 'user_groups'
                                   and on_what_id = p.group_id)) or (lower(project_type) in ('client - full service')
               and exists (select 1
                             from survsimp_surveys
                            where short_name in ('project_report'))
               and not exists (select 1
                                 from survsimp_responses
                                where survey_id=(select survey_id 
                                                   from survsimp_surveys
                                                  where short_name in ('project_report'))
                                  and submission_date &gt; sysdate - 7
                                  and group_id=p.group_id)) )</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t96 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  2 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t96 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  20 ms  </td><td bgcolor="#FFFFFF">select nsdb2 (main pool)
<blockquote><pre>select distinct u.user_id
           from users_active u, user_group_map ugm
          where u.user_id = ugm.user_id
            and ugm.group_id = 6
            and u.portrait is not null</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  3 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  2 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  52 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  4 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  3 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  4 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  2 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  8 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  16 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  2 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  2 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t103 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  33 ms  </td><td bgcolor="#FFFFFF">0or1row nsdb2 (main pool)
<blockquote><pre>
select u.first_names || ' ' || u.last_name as name, u.bio, u.skills, 
                    ug.group_name as office, ug.group_id as office_id
               from im_employees_active u, user_groups ug, user_group_map ugm
              where u.user_id = ugm.user_id(+)
                and ug.group_id = ugm.group_id
                and ug.parent_group_id = 5
                and u.user_id = 1678
                and rownum &lt; 2</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  12 ms  </td><td bgcolor="#DDDDDD">select nsdb2 (main pool)
<blockquote><pre>select ug.group_id, ug.group_name, ai.url as ai_url
from  user_groups ug, administration_info ai
where ug.group_id = ai.group_id
and ad_group_member_p ( 1472, ug.group_id ) = 't'</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">getrow nsdb2 t207 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  119 ms  </td><td bgcolor="#DDDDDD">getrow nsdb2 t207 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  1 ms  </td><td bgcolor="#FFFFFF">releasehandle nsdb2 (main pool)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">gethandle log (returned nsdb3)</td>
</tr><tr valign="top">
<td align="right" bgcolor="#FFFFFF" nowrap="nowrap">
  11 ms  </td><td bgcolor="#FFFFFF">1row nsdb3 (log pool)
<blockquote><pre>
select ad_group_member_p(1472, system_administrator_group_id) from dual</pre></blockquote>
</td>
</tr><tr valign="top">
<td align="right" bgcolor="#DDDDDD" nowrap="nowrap">
  1 ms  </td><td bgcolor="#DDDDDD">releasehandle nsdb3 (log pool)</td>
</tr><tr>
<td bgcolor="black" align="right"><font color="white"><strong>  3678 ms  </strong></font></td><th align="left">(total)</th>
</tr>
</table></blockquote>
<hr>
<a href="mailto:webmaster\@dev.arsdigita.com"><address>webmaster\@dev.arsdigita.com</address></a>
<p>Last Modified: $&zwnj;Id: developer-support-example.html,v 1.2
2017/08/07 23:47:56 gustafn Exp $</p>
