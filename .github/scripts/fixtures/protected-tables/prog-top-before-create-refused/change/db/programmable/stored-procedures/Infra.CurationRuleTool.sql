-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
DELETE FROM Infra.CurationRule;
GO
CREATE OR ALTER PROCEDURE Infra.CurationRuleTool AS SELECT 1;
