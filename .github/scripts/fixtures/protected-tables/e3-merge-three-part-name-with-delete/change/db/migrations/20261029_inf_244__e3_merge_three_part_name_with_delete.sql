CREATE TABLE #incoming (RuleId INT NOT NULL);
MERGE Tenant1.Infra.CurationRule AS t
USING #incoming AS s ON t.RuleId = s.RuleId
WHEN NOT MATCHED BY SOURCE THEN DELETE;
