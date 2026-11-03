-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
ALTER PROCEDURE Infra.CurationRuleTool AS DELETE FROM Infra.CurationRule WHERE RuleId = 0;
