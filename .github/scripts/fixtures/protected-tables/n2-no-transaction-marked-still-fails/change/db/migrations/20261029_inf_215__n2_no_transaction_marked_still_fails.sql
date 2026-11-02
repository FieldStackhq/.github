-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
-- @no-transaction
ALTER TABLE Infra.CurationRule ADD Priority INT NULL;
