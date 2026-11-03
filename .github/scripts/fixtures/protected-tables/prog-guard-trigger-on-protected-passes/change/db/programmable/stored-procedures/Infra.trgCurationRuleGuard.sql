CREATE OR ALTER TRIGGER Infra.trgCurationRuleGuard ON Infra.CurationRule AFTER DELETE AS BEGIN ROLLBACK; THROW 50000, N'no deletes', 1; END;
