CREATE TABLE #ids (RuleId INT NOT NULL);
WITH stale AS (SELECT * FROM Infra.CurationRule WHERE IsActive = 0)
DELETE s FROM stale s JOIN #ids i ON i.RuleId = s.RuleId;
