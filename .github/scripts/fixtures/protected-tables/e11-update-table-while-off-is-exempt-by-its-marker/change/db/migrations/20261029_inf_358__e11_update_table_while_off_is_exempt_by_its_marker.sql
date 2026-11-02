-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE Infra.CurationRule ADD Priority INT NULL;
UPDATE Infra.CurationRule SET Priority = 0;
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Infra.CurationRuleHistory));
