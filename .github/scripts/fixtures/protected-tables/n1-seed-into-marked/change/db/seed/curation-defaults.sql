-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
SELECT RuleId INTO #snapshot FROM Infra.CurationRule;
