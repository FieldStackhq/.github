-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
DECLARE @a NVARCHAR(400) = N'Infra.CurationRule.Note';
DECLARE @b NVARCHAR(400) = N'Infra.CurationRuleHistory.Note';
EXEC sp_rename @b, N'Remark', N'COLUMN';
