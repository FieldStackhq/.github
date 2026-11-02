ALTER TABLE Infra.CurationRule ADD Priority INT NULL
GOTO done
done:
ALTER TABLE dbo.Widget DROP COLUMN Legacy
