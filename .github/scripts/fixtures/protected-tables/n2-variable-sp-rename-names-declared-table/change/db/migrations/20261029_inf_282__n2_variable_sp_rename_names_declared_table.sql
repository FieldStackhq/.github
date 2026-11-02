-- @no-transaction
DECLARE @old NVARCHAR(400) = N'Infra.CurationRuleHistory.Note';
EXEC sp_rename @old, N'Remark', N'COLUMN';
