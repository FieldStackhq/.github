-- MIGRATION SAFETY: Infra.CurationRuleHistory -- Reviewed with Jeff, data is restored from the blob copy.
INSERT INTO Infra.CurationRuleHistory (RuleId, Note) VALUES (1, N'old');
