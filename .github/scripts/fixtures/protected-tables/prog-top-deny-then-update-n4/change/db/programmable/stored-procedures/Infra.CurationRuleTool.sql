CREATE OR ALTER PROC Infra.CurationRuleTool AS SELECT 1;
GO
DENY DELETE ON Infra.CurationRule TO [svc_vireots_ro]
UPDATE Infra.CurationRule SET RuleId = 2;
