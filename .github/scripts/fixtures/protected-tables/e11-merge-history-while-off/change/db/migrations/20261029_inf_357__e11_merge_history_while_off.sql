-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = OFF);
MERGE Infra.CurationRuleHistory AS h USING (VALUES (1)) AS s (RuleId) ON h.RuleId = s.RuleId
WHEN MATCHED THEN UPDATE SET h.RuleId = s.RuleId;
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Infra.CurationRuleHistory));
