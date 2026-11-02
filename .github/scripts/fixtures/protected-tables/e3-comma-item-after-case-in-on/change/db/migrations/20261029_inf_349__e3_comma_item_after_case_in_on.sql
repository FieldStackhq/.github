CREATE TABLE #ids (RuleId INT NOT NULL);
DELETE r FROM #ids i JOIN #b b ON i.RuleId = CASE WHEN b.RuleId = 1 THEN b.RuleId END, Infra.CurationRule r WHERE r.RuleId = i.RuleId;
