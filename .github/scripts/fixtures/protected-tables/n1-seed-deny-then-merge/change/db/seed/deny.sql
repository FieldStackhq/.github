DENY SELECT ON dbo.X TO [r]
MERGE Infra.CurationRule AS t USING #s AS s ON t.RuleId = s.RuleId WHEN MATCHED THEN UPDATE SET RuleId = 3;
