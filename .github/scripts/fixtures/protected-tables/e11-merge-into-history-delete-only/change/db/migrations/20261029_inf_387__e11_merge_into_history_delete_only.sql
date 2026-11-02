MERGE Infra.CurationRuleHistory AS h USING #s AS s ON h.RuleId = s.RuleId WHEN MATCHED THEN DELETE;
