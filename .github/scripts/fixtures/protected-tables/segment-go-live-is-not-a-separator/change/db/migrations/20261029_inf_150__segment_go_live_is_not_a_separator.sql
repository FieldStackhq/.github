ALTER TABLE Infra.CurationRule ADD Priority INT NULL
SELECT go_live FROM dbo.Release
ALTER TABLE dbo.Widget DROP COLUMN Legacy
