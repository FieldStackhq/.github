-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
ALTER TABLE Infra.CurationRule
    DROP COLUMN Note;
