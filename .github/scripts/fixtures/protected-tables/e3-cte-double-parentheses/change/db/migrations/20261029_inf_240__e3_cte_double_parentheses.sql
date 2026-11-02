WITH stale AS ((SELECT * FROM Infra.CurationRule WHERE IsActive = 0))
DELETE FROM stale;
