-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
EXEC sp_rename 'Infra.CurationRule', 'CurationRuleOld';
