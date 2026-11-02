-- migration safety: Infra.CurationRule -- Note column was never populated.
ALTER TABLE Infra.CurationRule
    DROP COLUMN Note;
