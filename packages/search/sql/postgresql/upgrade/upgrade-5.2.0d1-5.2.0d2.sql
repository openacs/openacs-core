-- define args so we can package_exec_plsql
-- JCD

select define_function_args('search_observer__enqueue','object_id,event');
select define_function_args('search_observer__dequeue','object_id,event_date,event');
