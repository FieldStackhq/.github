CREATE OR ALTER PROC Infra.CurationRuleTool AS SELECT 1;
GO
DENY DELETE, UPDATE ON Infra.CurationRule TO [svc_vireots_ro];
