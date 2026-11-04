CREATE TRIGGER dbo.trgOther ON dbo.Other AFTER INSERT AS INSERT INTO Infra.CurationRule (RuleId) SELECT RuleId FROM inserted;
