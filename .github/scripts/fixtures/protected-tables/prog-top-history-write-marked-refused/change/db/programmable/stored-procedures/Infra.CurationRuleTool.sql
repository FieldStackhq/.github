-- MIGRATION SAFETY: Infra.CurationRuleHistory -- Reviewed with Jeff, data is restored from the blob copy.
CREATE OR ALTER PROC Infra.CurationRuleTool AS SELECT 1;
GO
INSERT INTO Infra.CurationRuleHistory (RuleId) VALUES (1);
