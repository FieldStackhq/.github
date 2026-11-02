-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = ON (DATA_CONSISTENCY_CHECK = ON, HISTORY_TABLE = Infra.CurationRuleHistory));
