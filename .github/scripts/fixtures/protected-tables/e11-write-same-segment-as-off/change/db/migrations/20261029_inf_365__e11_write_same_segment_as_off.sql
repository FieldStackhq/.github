-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = OFF)
UPDATE Infra.CurationRuleHistory SET RuleId = 2;
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Infra.CurationRuleHistory));
