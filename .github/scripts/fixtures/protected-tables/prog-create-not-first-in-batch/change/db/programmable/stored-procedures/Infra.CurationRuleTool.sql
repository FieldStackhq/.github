-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
SET ANSI_NULLS ON;
CREATE OR ALTER PROC Infra.CurationRuleTool AS DELETE FROM Infra.CurationRule;
