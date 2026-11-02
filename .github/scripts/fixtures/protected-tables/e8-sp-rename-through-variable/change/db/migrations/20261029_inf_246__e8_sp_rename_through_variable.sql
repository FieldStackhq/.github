DECLARE @old NVARCHAR(400) = N'Infra.CurationRule.Note';
EXEC sp_rename @old, N'Remark', N'COLUMN';
