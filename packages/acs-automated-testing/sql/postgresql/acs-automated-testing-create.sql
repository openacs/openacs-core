----------------------------------------------------------------------------
--
--   aa-test-create.sql
--   Script to create Testing tables.
--
--   Copyright 2001, OpenMSG Ltd, Peter Harper.
--
--   This file is part of aa-test.
--
--   aa-test is free software; you can redistribute it and/or modify
--   it under the terms of the GNU General Public License as published by
--   the Free Software Foundation; either version 2 of the License, or
--   (at your option) any later version.
--
--   aa-test is distributed in the hope that it will be useful,
--   but WITHOUT ANY WARRANTY; without even the implied warranty of
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--   GNU General Public License for more details.
--
--   You should have received a copy of the GNU General Public License
--   along with aa-test; if not, write to the Free Software
--   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
--
----------------------------------------------------------------------------

create table aa_test_results (
  testcase_id        varchar(512),
  package_key        varchar(100),
  test_id            integer,
  timestamp          timestamptz,
  result             varchar(4),
  notes              varchar(2000)
);


create table aa_test_final_results (
  testcase_id        varchar(512),
  package_key        varchar(100),
  timestamp          timestamptz,
  passes             integer,
  fails              integer
);
