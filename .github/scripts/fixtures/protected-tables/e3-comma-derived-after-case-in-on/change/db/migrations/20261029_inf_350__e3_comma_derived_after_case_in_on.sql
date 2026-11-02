CREATE TABLE #ids (RuleId INT NOT NULL);
DELETE d FROM #ids i JOIN #b b ON i.RuleId = CASE WHEN b.RuleId = 1 THEN b.RuleId END, (SELECT TOP (5) * FROM Infra.CurationRule ORDER BY RuleId) AS d;
