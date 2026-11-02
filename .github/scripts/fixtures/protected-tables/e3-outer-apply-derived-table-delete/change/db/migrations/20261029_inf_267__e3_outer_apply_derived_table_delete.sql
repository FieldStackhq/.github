CREATE TABLE #ids (RuleId INT NOT NULL);
DELETE x FROM #ids i OUTER APPLY (SELECT TOP (5) * FROM Infra.CurationRuleHistory h WHERE h.RuleId = i.RuleId ORDER BY h.ValidTo) x;
