-- MIGRATION SAFETY: dropping the unused Note column, safe to remove
ALTER TABLE Infra.CurationRule
    DROP COLUMN Note;
