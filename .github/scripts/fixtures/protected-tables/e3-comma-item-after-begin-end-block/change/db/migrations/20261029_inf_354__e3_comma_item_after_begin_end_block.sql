CREATE TABLE #ids (RuleId INT NOT NULL);
IF 1 = 1 BEGIN SELECT 1 END
DELETE r FROM #ids i, Infra.CurationRule r WHERE r.RuleId = i.RuleId;
