-- MIGRATION SAFETY: dropping the unused Note column -- safe because nothing reads it
ALTER TABLE Infra.CurationRule
    DROP COLUMN Note;
