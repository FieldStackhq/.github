-- MIGRATION SAFETY: Infra.Foo%0A -- reason
ALTER TABLE Infra.CurationRule
    DROP COLUMN Note;
