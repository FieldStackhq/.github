SELECT r.RuleId FROM Infra.CurationRule r WHERE r.IsActive = 0
SELECT r.RuleId FROM Infra.CurationRuleHistory r WHERE r.IsActive = 0
DELETE r WHERE r.RuleId = 2;
