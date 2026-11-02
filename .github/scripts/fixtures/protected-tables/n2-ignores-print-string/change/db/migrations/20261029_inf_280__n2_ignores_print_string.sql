-- @no-transaction
PRINT N'Infra.CurationRuleHistory';
ALTER TABLE Infra.CurationRule ADD Priority INT NULL;
