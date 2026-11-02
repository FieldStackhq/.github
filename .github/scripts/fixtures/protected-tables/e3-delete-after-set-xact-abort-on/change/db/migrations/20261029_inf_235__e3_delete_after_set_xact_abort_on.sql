CREATE TABLE #ids (RuleId INT NOT NULL);
SET XACT_ABORT ON
DELETE h FROM #ids i JOIN Infra.CurationRuleHistory h ON h.RuleId = i.RuleId;
