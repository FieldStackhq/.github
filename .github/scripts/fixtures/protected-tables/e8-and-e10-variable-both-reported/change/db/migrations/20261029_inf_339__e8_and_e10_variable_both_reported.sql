EXEC sp_rename N'Infra.CurationRule.Note', N'X', N'COLUMN';
DECLARE @o sysname = N'Infra.CurationRule';
EXEC sp_changeobjectowner @o, 'dbo';
