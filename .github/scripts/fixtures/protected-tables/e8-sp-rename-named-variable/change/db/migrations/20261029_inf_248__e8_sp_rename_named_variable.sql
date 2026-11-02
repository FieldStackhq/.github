DECLARE @old NVARCHAR(400) = N'Infra.CurationRule.Note';
EXEC sp_rename @objname = @old, @newname = N'Remark', @objtype = N'COLUMN';
