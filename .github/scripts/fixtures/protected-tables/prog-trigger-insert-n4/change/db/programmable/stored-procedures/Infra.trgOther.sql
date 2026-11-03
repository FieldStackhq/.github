CREATE OR ALTER TRIGGER Infra.trgOther ON Infra.Other AFTER INSERT AS INSERT INTO Infra.CurationRule (RuleId) SELECT RuleId FROM inserted;
