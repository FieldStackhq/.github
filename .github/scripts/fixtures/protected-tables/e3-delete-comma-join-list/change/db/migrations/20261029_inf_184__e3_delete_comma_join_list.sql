CREATE TABLE #ids (RuleId INT NOT NULL);
DELETE r FROM #ids i, Infra.CurationRule r WHERE r.RuleId = i.RuleId;
