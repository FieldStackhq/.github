CREATE TABLE #x (RuleId INT NOT NULL);
SELECT r.RuleId FROM Infra.CurationRule r WHERE r.IsActive = 0
SELECT r.RuleId FROM #x r
DELETE r FROM #x r WHERE r.RuleId = 2;
