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

set feedback off;

insert into long_term_issue_ratings
 values (1,'AAA','An obligation rated ''AAA'' has the highest rating assigned by Standard '||chr(38) ||' Poor''s. The obligor''s capacity to meet its financial commitment on the obligation is extremely strong.');
    
insert into long_term_issue_ratings
 values (2,'AA+','See AA');

insert into long_term_issue_ratings
 values (3,'AA','An obligation rated ''AA'' differs from the highest rated obligations only in small degree. The obligor''s capacity to meet its financial commitment on the obligation is very strong.');

insert into long_term_issue_ratings
 values (4,'AA-','See AA');

insert into long_term_issue_ratings
 values (5,'A+','See A');

insert into long_term_issue_ratings
 values (6,'A','An obligation rated ''A'' is somewhat more susceptible to the adverse effects of changes in circumstances and economic conditions than obligations in higher rated categories. However, the obligor''s capacity to meet its financial commitment on the obligation is still strong.');

insert into long_term_issue_ratings
 values (7,'A-','See A');

insert into long_term_issue_ratings
 values (8,'BBB+','See BBB');

insert into long_term_issue_ratings
 values (9,'BBB','An obligation rated ''BBB'' exhibits adequate protection parameters. However, adverse economic conditions or changing circumstances are more likely to lead to a weakened capacity of the obligor to meet its financial commitment on the obligation. Obligations rated ''BB'', ''B'', ''CCC'', ''CC'', and ''C'' are regarded as having significant speculative characteristics. ''BB'' indicates the least degree of speculation and ''C'' the highest. While such obligations will likely have some quality and protective characteristics, these may be outweighed by large uncertainties or major exposures to adverse conditions.');

insert into long_term_issue_ratings
 values (10,'BBB-','See BBB');

insert into long_term_issue_ratings
 values (11,'BB+','See BB');

insert into long_term_issue_ratings
 values (12,'BB','An obligation rated ''BB'' is less vulnerable to nonpayment than other speculative issues. However, it faces major ongoing uncertainties or exposure to adverse business, financial, or economic conditions which could lead to the obligor''s inadequate capacity to meet its financial commitment on the obligation.');

insert into long_term_issue_ratings
 values (13,'BB-','See BB');

insert into long_term_issue_ratings
 values (14,'B+','See B');

insert into long_term_issue_ratings
 values (15,'B','An obligation rated ''B'' is more vulnerable to nonpayment than obligations rated ''BB'', but the obligor currently has the capacity to meet its financial commitment on the obligation. Adverse business, financial, or economic conditions will likely impair the obligor''s capacity or willingness to meet its financial commitment on the obligation.');

insert into long_term_issue_ratings
 values (16,'B-','See B');

insert into long_term_issue_ratings
 values (17,'CCC+','See CCC');

insert into long_term_issue_ratings
 values (18,'CCC','An obligation rated ''CCC'' is currently vulnerable to nonpayment, and is dependent upon favorable business, financial, and economic conditions for the obligor to meet its financial commitment on the obligation. In the event of adverse business, financial, or economic conditions, the obligor is not likely to have the capacity to meet its financial commitment on the obligation.');

insert into long_term_issue_ratings
 values (19,'CCC-','See CCC');

insert into long_term_issue_ratings
 values (20,'CC','An obligation rated ''CC'' is currently highly vulnerable to nonpayment.');

insert into long_term_issue_ratings
 values (21,'C','A subordinated debt or preferred stock obligation rated ''C'' is CURRENTLY HIGHLY VULNERABLE to nonpayment. The ''C'' rating may be used to cover a situation where a bankruptcy petition has been filed or similar action taken, but payments on this obligation are being continued. A ''C'' also will be assigned to a preferred stock issue in arrears on dividends or sinking fund payments, but that is currently paying.');

insert into long_term_issue_ratings
 values (22,'D','An obligation rated ''D'' is in payment default. The ''D'' rating category is used when payments on an obligation are not made on the date due even if the applicable grace period has not expired, unless Standard '||chr(38)||' Poor''s believes that such payments will be made during such grace period. The ''D'' rating also will be used upon the filing of a bankruptcy petition or the taking of a similar action if payments on an obligation are jeopardized. Plus (+) or minus(-): The ratings from ''AA'' to ''CCC'' may be modified by the addition of a plus or minus sign to show relative standing within the major rating categories.');

insert into long_term_issue_ratings
 values (23,'r','This symbol is attached to the ratings of instruments with significant noncredit risks. It highlights risks to principal or volatility of expected returns which are not addressed in the credit rating. Examples include: obligations linked or indexed to equities, currencies, or commodities; obligations exposed to severe prepayment risk - such as interest-only or principal-only mortgage securities; and obligations with unusually risky interest terms, such as inverse floaters.');

insert into long_term_issue_ratings
 values (24,'N.R.','This indicates that no rating has been requested, that there is insufficient information on which to base a rating, or that Standard '||chr(38)||' Poor''s does not rate a particular obligation as a matter of policy.');

set feedback on;
commit;

  
