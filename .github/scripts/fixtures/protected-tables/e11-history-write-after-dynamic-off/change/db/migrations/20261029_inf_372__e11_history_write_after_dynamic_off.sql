EXEC (N'ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = OFF)');
INSERT INTO Infra.CurationRuleHistory (RuleId) VALUES (1);
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Infra.CurationRuleHistory));
