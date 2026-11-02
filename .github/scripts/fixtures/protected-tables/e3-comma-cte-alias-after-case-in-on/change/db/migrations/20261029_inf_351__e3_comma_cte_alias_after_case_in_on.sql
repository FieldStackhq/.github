CREATE TABLE #ids (RuleId INT NOT NULL);
WITH c AS (SELECT * FROM Infra.CurationRule)
DELETE s FROM #ids i JOIN #b b ON i.RuleId = CASE WHEN b.RuleId = 1 THEN b.RuleId END, c AS s;
