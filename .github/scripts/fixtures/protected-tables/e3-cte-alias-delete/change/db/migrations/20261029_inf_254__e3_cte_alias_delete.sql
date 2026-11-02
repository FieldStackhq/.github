WITH stale AS (SELECT * FROM Infra.CurationRule WHERE IsActive = 0)
DELETE s FROM stale AS s;
