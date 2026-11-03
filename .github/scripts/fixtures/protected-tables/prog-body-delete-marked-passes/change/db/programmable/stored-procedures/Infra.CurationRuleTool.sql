-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
CREATE OR ALTER PROC Infra.CurationRuleTool AS BEGIN SET NOCOUNT ON; DELETE FROM Infra.CurationRule WHERE RuleId = 0; END;
