--
-- acs-kernel/sql/acs-objects-test.sql
--
-- PL/SQL regression tests for the acs-objects system
--
-- Note: These tests use the utPLSQL regression package available at:
-- ftp://ftp.oreilly.com/published/oreilly/oracle/utplsql/utplsql.zip
--
-- @author Richard Li (richardl@arsdigita.com)
--
-- @creation-date 19 September 2000
--
-- @cvs-id $Id$

-- In order for utPLSQL to work, you need to grant 
-- specific permissions to your user:
--
-- grant create public synonym to servicename;
-- grant drop public synonym to servicename;
-- grant execute on dbms_pipe to servicename;
-- grant drop any table to servicename;
-- grant create any table to servicename;

-- In order to execute the test, you need to set things up
-- in your SQL*PLUS session. First type:
-- 
--     set serveroutput on size 1000000 format wrapped
--
-- Now, if you have the UTL_FILE PL/SQL package installed, type:
--
--     exec utplsql.setdir('/web/richard/packages/acs-kernel/sql');
--
-- Otherwise, you'll have to disable autocompilation and manually
-- compile:
--
--     exec utplsql.autocompile (false);
--     @acs-objects-test
--
-- To actually execute the test, type:
--
--     exec utplsql.test('acs_object');


-- we need these here or else the PL/SQL won't compile.
drop table ut_acs_objects;
create table ut_acs_objects as select * from acs_objects;
create table test_objects (test_id integer primary key, data varchar2(100));

create or replace package ut#acs_object
as

    procedure setup;

    procedure teardown;

    procedure new;

    procedure del;

    procedure name;

    procedure default_name;

    procedure set_attribute;

    procedure get_attribute;

end ut#acs_object;
/
show errors

create or replace package body ut#acs_object
as

    procedure setup
    is
        attr_id acs_attributes.attribute_id%TYPE;
    begin
	teardown;
        dbms_output.put_line('Setting up...');

	-- create a copy of the table
 	execute immediate 'create table ut_acs_objects as
 		select * from acs_objects';

	execute immediate 'create table test_objects (test_id integer primary key, data varchar2(100))';

        -- create the test_object type
        acs_object_type.create_type (
	    supertype => 'acs_object',
     	    object_type => 'test_object',
	    pretty_name => 'Test Object',
	    pretty_plural => 'Test Objects',
            table_name => 'test_objects',
	    id_column => 'test_id'
	);

	-- no API available for this yet
	insert into acs_object_type_tables (object_type, table_name, id_column)
        values ('test_object','test_objects','test_id');

	-- create the attribute
	attr_id := acs_attribute.create_attribute (
	    object_type => 'test_object',
	    attribute_name => 'data',
	    pretty_name => 'Data',
	    pretty_plural => 'Mo Data',
	    datatype => 'string',
            table_name => 'test_objects',
	    column_name => 'data'
	);

        utplsql.setpkg('acs_object');
        utplsql.addtest('new');
        utplsql.addtest('delete');
        utplsql.addtest('name');
        utplsql.addtest('default_name');
        utplsql.addtest('set_attribute');
        utplsql.addtest('get_attribute');
    end;

    procedure teardown
    is
    begin
        dbms_output.put_line('Tearing down...');
	-- delete the test object
	delete from acs_attributes where object_type = 'test_object';
	delete from acs_objects where object_type = 'test_object';
	delete from acs_object_type_tables where object_type = 'test_object';

    	begin
    	    execute immediate 'drop table test_objects';
             exception
               when others
               then
                   null;
        end;

 	-- clean out the test data
  	begin
  	    execute immediate 'drop table ut_acs_objects';
            exception
              when others
              then
                  null;
        end;

	-- delete the object_type
	delete from acs_object_types where object_type = 'test_object';
    end;

    procedure new
    is
    begin
        dbms_output.put_line('Testing new...');
        -- Tests just the common functionality of the API.

	utassert.eq (
	    msg_in => 'Creating a new test object',
	    check_this_in => acs_object.new(object_id => -1000, object_type => 'test_object'),
	    against_this_in => -1000
        );

	-- create an object
	insert into ut_acs_objects(object_id, object_type, creation_date, security_inherit_p, last_modified)
        values(-1000, 'test_object', sysdate, 't', sysdate);
	
	-- Verify that the API does the correct insert.
	utassert.eqtable (
	    msg_in => 'Comparing created data for object',
	    check_this_in => 'acs_objects',
	    against_this_in => 'ut_acs_objects'
        );

	utresult.show;
	
    end;

    procedure del
    is
    begin
        dbms_output.put_line('Testing delete...');

	-- create a new object to delete; note that this test assumes that
	-- the .new operator works.
	utassert.eq (
	    msg_in => 'Creating a new test object',
	    check_this_in => acs_object.new(object_id => -1001, object_type => 'test_object'),
	    against_this_in => -1001
        );

	-- delete the row.
	acs_object.del(object_id => -1001);

 	-- verify object not there.
 	utassert.eqtable (
 	    msg_in => 'Delete verification',
 	    check_this_in => 'acs_objects',
 	    against_this_in => 'ut_acs_objects'
        );

	utresult.show;

    end;    

    procedure name
    is
    begin
	dbms_output.put_line('Testing name...');

	utassert.eq (
	    msg_in => 'Creating a name',
	    check_this_in => acs_object.name(object_id => -1000),
	    against_this_in => 'Test Object -1000'
        );

        utresult.show;

    end;

    procedure default_name
    is
    begin
	dbms_output.put_line('Testing default_name...');

	utassert.eq (
	    msg_in => 'Creating a name',
	    check_this_in => acs_object.default_name(object_id => -1000),
	    against_this_in => 'Test Object -1000'
        );

	utresult.show;

    end;

    procedure set_attribute
    is
        v_sql_result test_objects.data%TYPE;
    begin
        dbms_output.put_line('Testing set_attribute');

	utassert.eq (
	    msg_in => 'Creating a new test object',
	    check_this_in => acs_object.new(object_id => -1003, object_type => 'test_object'),
	    against_this_in => -1003
        );

	-- since we didn't create a test object new constructor
	-- we're going to insert into attributes here.
	insert into test_objects(test_id) values(-1003);

	acs_object.set_attribute(object_id_in => -1003,
                                 attribute_name_in => 'data',
                                 value_in => '2702');

	-- since utassert isn't powerful enough right now, we do this
	-- comparison manually
	select data into v_sql_result from test_objects where test_id = -1003;

	if v_sql_result = 2702 then
	    dbms_output.put_line('SUCCESS: set_attribute');
        else
            dbms_output.put_line('Verifying attribute data FAILED');
        end if;

	utresult.show;

    end;

    procedure get_attribute
    is
        v_attr_value varchar2(4000);
    begin
        dbms_output.put_line('Testing get_attribute');

	-- we assume that set attribute works. since i'm lazy
	-- i'm going to recycle the -1003 object.
	acs_object.set_attribute(object_id_in => -1003,
                                 attribute_name_in => 'data',
                                 value_in => 'sugarwen');

	v_attr_value := acs_object.get_attribute(object_id_in => -1003,
                                                 attribute_name_in => 'data');

	if v_attr_value = 'sugarwen' then
    	    dbms_output.put_line('SUCCESS: get_attribute');
        else
            dbms_output.put_line('Verifying get attribute data FAILED');
        end if;

	utresult.show;

    end;

end ut#acs_object;
/
show errors

