--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--

\i notifications-core-create.sql
\i notifications-package-create.sql

-- replies
\i notifications-replies-create.sql
\i notifications-replies-package-create.sql

-- the service contracts will eventually be created
-- @ notifications-interval-sc-create.sql
-- @ notifications-delivery-sc-create.sql

\i notification-type-sc-create.sql

\i delivery-method-sc-create.sql
\i notifications-init.sql
\i email-sc-impl-create.sql
