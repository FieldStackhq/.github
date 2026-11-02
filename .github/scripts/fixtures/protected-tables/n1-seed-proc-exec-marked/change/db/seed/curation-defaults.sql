-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
EXEC Infra.CurationRuleUpsert @RuleId = 1, @Note = N'seed';
