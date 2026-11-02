-- MIGRATION SAFETY: Infra.CurationRuleHistory -- Reviewed with Jeff, data is restored from the blob copy.
ALTER TABLE Infra.CurationRuleHistory SWITCH PARTITION 1 TO dbo.CurationRuleHistoryStage;
