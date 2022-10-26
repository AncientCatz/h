DROP INDEX IF EXISTS report.annotations_uuid_idx;
DROP INDEX IF EXISTS report.annotations_created_idx;
DROP INDEX IF EXISTS report.annotations_updated_idx;

INSERT INTO report.annotations (
    uuid,
    user_id, group_id, document_id, authority_id,
    created, updated,
    deleted, shared, size,
    parent_uuids, tags
)
SELECT
    annotation.id as uuid,
    users.id as user_id,
    groups.id as group_id,
    document_id,
    authorities.id as authority_id,
    annotation.created::date,
    -- As we do our partial updates based on updated date, it's good if this
    -- is actually high res timestamp, so we get less overlap
    annotation.updated,
    deleted,
    shared,
    LENGTH(text) AS size,
    "references",
    tags
-- <<< Here is our fake-out partial run >>>
FROM (SELECT * FROM annotation LIMIT 5000000) AS annotation
JOIN "user" users ON
    users.authority = SPLIT_PART(annotation.userid, '@', 2)
    AND users.username = SUBSTRING(SPLIT_PART(annotation.userid, '@', 1), 6)
JOIN "group" as groups ON
    groups.pubid = annotation.groupid
JOIN report.authorities ON
    authorities.authority = users.authority
 -- Ensure our data is in created order for nice correlation
ORDER BY annotation.created
ON CONFLICT DO NOTHING;

CREATE UNIQUE INDEX annotations_uuid_idx ON report.annotations (uuid);
CREATE INDEX annotations_created_idx ON report.annotations (created);
CREATE INDEX annotations_updated_idx ON report.annotations (updated);

ANALYZE report.annotations;
