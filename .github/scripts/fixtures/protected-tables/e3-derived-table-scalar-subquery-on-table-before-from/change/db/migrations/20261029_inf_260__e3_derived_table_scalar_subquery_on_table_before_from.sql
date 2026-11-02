CREATE TABLE #tmp (RuleId INT NOT NULL);
DELETE x FROM (SELECT (SELECT TOP (1) RuleId FROM Infra.CurationRule) AS FirstRule, t.RuleId FROM #tmp t) AS x;
