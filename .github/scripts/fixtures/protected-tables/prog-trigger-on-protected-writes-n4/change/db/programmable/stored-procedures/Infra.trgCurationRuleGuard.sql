CREATE OR ALTER TRIGGER Infra.trgCurationRuleGuard ON Infra.CurationRule AFTER UPDATE AS UPDATE Infra.CurationRule SET Note = N'x' WHERE RuleId IN (SELECT RuleId FROM inserted);
