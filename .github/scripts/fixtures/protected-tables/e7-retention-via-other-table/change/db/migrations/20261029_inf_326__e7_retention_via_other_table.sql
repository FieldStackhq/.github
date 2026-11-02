-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE dbo.Other SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Infra.CurationRuleHistory, HISTORY_RETENTION_PERIOD = 1 DAY));
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Infra.CurationRuleHistory));
