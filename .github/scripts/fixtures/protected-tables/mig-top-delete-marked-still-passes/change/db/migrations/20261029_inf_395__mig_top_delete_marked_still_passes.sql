-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
DELETE FROM Infra.CurationRule WHERE RuleId = 0;
