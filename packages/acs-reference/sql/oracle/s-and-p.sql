-- packages/acs-reference/sql/oracle/s-and-p-data.sql
--
-- @author jon@jongriffin.com
-- @creation-date 2000-11-21
-- @cvs-id $Id$

create table long_term_issue_ratings (
    -- this is the sort key
    rank  integer
        constraint long_term_issue_rank_pk
        primary key,
    -- the actual rating
    rating char(4)
        constraint long_term_issue_rating_uq
        unique
        constraint long_term_issue_rating_nn
        not null,
    description varchar2(1000)
);

comment on table long_term_issue_ratings is '
    This is a sample of some of the non-standards based standards.
    It is the Standard y Poor''s credit ratings.
';

comment on column long_term_issue_ratings.rank is '
    This is the rank with AAA+ being highest.
';

-- now register this table with the repository

declare
    v_id integer;
begin
    v_id := acs_reference.new(
        table_name     => 'LONG_TERM_ISSUE_RATINGS',
        source         => 'Standard '||chr(38)||' Poor''s',
        source_url     => 'http://www.standardandpoors.com/ratings/corporates/index.htm',
        effective_date => sysdate
    );
end;
/

-- now add data
@@../common/s-and-p-data.sql

  
