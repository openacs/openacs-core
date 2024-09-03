--
-- Add membership "expired" to membership states.  "expired" can be
-- used for "dormant" accounts, which are neither "banned" or
-- "deleted".
-- 
ALTER TABLE membership_rels DROP CONSTRAINT membership_rels_member_state_ck;
ALTER TABLE membership_rels ADD CONSTRAINT membership_rels_member_state_ck
            CHECK (member_state in ('merged','approved', 'needs approval',
                                    'banned', 'rejected', 'deleted', 'expired'));
