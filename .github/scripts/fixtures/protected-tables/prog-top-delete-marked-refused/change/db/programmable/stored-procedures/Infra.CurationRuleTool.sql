-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
CREATE OR ALTER PROC Infra.CurationRuleTool AS SELECT 1;
GO
DELETE FROM Infra.CurationRule;
