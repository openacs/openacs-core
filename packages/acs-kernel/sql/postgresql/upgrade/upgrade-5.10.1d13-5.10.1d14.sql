--
-- Create a partial index for a very common case.
--
CREATE INDEX CONCURRENTLY IF NOT EXISTS
membership_rels_rel_id_approved_idx ON membership_rels(rel_id) WHERE member_state = 'approved';
