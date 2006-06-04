--
-- packages/acs-kernel/sql/site-node-selection.sql
--
-- @author vivian@viaro.net
-- @creation-date 2004-11-23
-- @cvs-id site-node-selection.sql
--

create table site_nodes_selection (
        node_id         integer constraint site_nodes_sel_id_fk
                        references acs_objects (object_id)
                        constraint site_node_sel_id_pk
                        primary key,
	view_p		char(1)
                constraint site_nodes_sel_view_p_ck
                check (view_p in ('t','f'))
);

--show errors