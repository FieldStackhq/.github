CREATE TABLE #ids (RuleId INT NOT NULL);
DELETE r FROM (Infra.CurationRule r JOIN #ids i ON i.RuleId = r.RuleId);
