-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
CREATE OR ALTER PROC Infra.CurationRuleTool AS SELECT 1;
GO
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = OFF);
INSERT INTO Infra.CurationRule (RuleId) VALUES (1);
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Infra.CurationRuleHistory));
