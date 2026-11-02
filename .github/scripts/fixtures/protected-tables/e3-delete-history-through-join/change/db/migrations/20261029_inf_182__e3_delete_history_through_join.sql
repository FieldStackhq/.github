CREATE TABLE #ids (RuleId INT NOT NULL);
DELETE h FROM #ids i JOIN Infra.CurationRuleHistory h ON h.RuleId = i.RuleId;
