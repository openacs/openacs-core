-- packages/ref-timezones/sql//common/ref-timezones-rules.sql
--
-- This file is generated automatically based on the Unix timezone
-- database.  It defines each time range during which a particular
-- local-to-UTC conversion rule is in effect.  The rules specification
-- is of the form:
--
-- where
--
--    tz                is the Unix timezone name
--    abbrev            is an abbreviation for the conversion rule,
--    isdist            is the Daylight Savings Time flag
--    gmt_offset        is the difference between local time and UTC in seconds
--    utc_[start,end]   are the UTC times during which the rule applies
--    local_[start,end] are the local times during which this rule applies.
--
-- Note that local times are discontinuous because of DST transitions.
--
-- Rules in general run until 2038.
--
-- @author Jon Griffin (jon@jongriffin.com)
--
-- @created 2000-12-04
--
-- $Id$

insert into timezone_rules values (1,'GMT',rdbms_date('Dec 14 1901 08:45:52'),rdbms_date('Jan 01 1912 12:16:07'),rdbms_date('Dec 14 1901 08:29:44'),rdbms_date('Dec 31 1911 11:59:59'),-968,'f');
insert into timezone_rules values (1,'GMT',rdbms_date('Jan 01 1912 12:16:08'),rdbms_date('Jan 18 2038 03:14:07'),rdbms_date('Jan 01 1912 12:16:08'),rdbms_date('Jan 18 2038 03:14:07'),0,'f');     
insert into timezone_rules values (2,'GMT',rdbms_date('Dec 14 1901 08:45:52'),rdbms_date('Jan 01 1918 12:00:51'),rdbms_date('Dec 14 1901 08:45:00'),rdbms_date('Dec 31 1917 11:59:59'),-52,'f');   
insert into timezone_rules values (2,'GMT',rdbms_date('Jan 01 1918 12:00:52'),rdbms_date('Aug 31 1936 11:59:59'),rdbms_date('Jan 01 1918 12:00:52'),rdbms_date('Aug 31 1936 11:59:59'),0,'f');     
