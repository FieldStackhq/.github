CREATE OR ALTER PROC Infra.CurationRuleTool AS SELECT 1;
GO
DENY DELETE TO [svc_vireots_ro]
UPDATE Infra.CurationRule SET RuleId = 2 FROM Infra.CurationRule AS t JOIN #s AS s ON s.RuleId = t.RuleId;
