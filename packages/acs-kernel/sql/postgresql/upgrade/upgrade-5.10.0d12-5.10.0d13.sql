
--
-- site nodes reform part 2:
--
-- This upgrade script completes the commits "change queries on
-- site-node tree from tree_sortkey to recursive queries" from Oct 21,
-- 2018, 4 months ago.  This upgrade has the purpose to drop the now
-- obsolete triggers and indices.
--
-- Delaying the 2nd part had the purpose to make upgrades more smooth,
-- at least for upgrades via .apm files. Without site nodes working,
-- users cannot navigate on their server unless it is restarted.
--
--    http://fisheye.openacs.org/changelog/OpenACS?cs=MAIN%3Agustafn%3A20181021173623
--    http://fisheye.openacs.org/changelog/OpenACS?cs=MAIN%3Agustafn%3A20181021175135
--    http://fisheye.openacs.org/changelog/OpenACS?cs=MAIN%3Agustafn%3A20181022074137
--    http://fisheye.openacs.org/changelog/OpenACS?cs=MAIN%3Agustafn%3A20181022085126
--    http://fisheye.openacs.org/changelog/OpenACS?cs=MAIN%3Agustafn%3A20181022081230
-- 
-- delete tree_sortkeys and management code for tree_sortkeys
--
DROP FUNCTION IF EXISTS site_node_get_tree_sortkey(integer);

DROP TRIGGER IF EXISTS site_node_insert_tr on site_nodes;
DROP FUNCTION IF EXISTS site_node_insert_tr();

DROP TRIGGER IF EXISTS site_node_update_tr on site_nodes;
DROP FUNCTION IF EXISTS site_node_update_tr();

DROP INDEX IF EXISTS site_nodes_tree_skey_idx;
ALTER TABLE site_nodes DROP COLUMN IF EXISTS tree_sortkey;
