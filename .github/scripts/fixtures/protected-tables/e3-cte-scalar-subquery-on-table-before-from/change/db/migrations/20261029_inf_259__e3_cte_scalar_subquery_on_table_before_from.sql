CREATE TABLE #tmp (RuleId INT NOT NULL);
WITH f AS (SELECT (SELECT TOP (1) RuleId FROM Infra.CurationRule) AS FirstRule, t.RuleId FROM #tmp t)
DELETE FROM f;
