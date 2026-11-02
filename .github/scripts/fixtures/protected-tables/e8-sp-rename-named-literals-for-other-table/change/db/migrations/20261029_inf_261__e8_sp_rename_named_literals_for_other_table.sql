ALTER TABLE Infra.CurationRule ADD Priority INT NULL;
EXEC sp_rename @objname = N'dbo.Widget.Name', @newname = N'Label', @objtype = N'COLUMN';
