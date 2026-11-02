CREATE TABLE #ids (RuleId INT NOT NULL);
DELETE x FROM #ids i CROSS APPLY (SELECT TOP (1) * FROM Infra.CurationRule r WHERE r.RuleId = i.RuleId ORDER BY r.RuleId) AS x;
