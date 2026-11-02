-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
DECLARE @old NVARCHAR(400) = N'Infra.CurationRule.Note';
EXEC sp_rename @old, N'Remark', N'COLUMN';
