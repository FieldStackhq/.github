-- MIGRATION SAFETY: Infra.CurationRule
ALTER TABLE Infra.CurationRule
    DROP COLUMN Note;
