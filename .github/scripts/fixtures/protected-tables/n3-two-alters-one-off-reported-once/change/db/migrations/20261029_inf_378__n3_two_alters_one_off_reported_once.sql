-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
ALTER TABLE Infra.CurationRule ADD Note2 INT NULL
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = OFF);
