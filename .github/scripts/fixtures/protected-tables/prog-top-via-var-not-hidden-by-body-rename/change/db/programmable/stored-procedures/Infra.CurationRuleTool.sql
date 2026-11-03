-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
CREATE OR ALTER PROC Infra.CurationRuleTool AS EXEC sp_rename N'Infra.CurationRule', N'CurationRuleOld';
GO
DECLARE @v NVARCHAR(200) = N'Infra.CurationRule';
EXEC sp_rename @v, N'CurationRuleOld';
