WITH stale AS (SELECT * FROM Tenant1.Infra.CurationRule WHERE IsActive = 0)
DELETE FROM stale;
