-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
DECLARE @rc INT;
EXEC @rc = Infra.CurationRuleUpsert @RuleId = 1, @Note = N'seed';
