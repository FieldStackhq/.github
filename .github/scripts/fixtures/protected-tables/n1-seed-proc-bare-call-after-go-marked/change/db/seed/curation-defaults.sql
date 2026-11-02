-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
SET NOCOUNT ON;
GO
Infra.CurationRuleUpsert @RuleId = 1, @Note = N'seed';
