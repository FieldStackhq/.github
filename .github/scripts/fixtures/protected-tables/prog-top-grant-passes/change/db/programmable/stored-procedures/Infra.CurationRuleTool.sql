CREATE OR ALTER PROC Infra.CurationRuleTool AS SELECT 1;
GO
IF DATABASE_PRINCIPAL_ID(N'svc_vireots_ro') IS NOT NULL GRANT EXECUTE ON OBJECT::[Infra].[CurationRuleTool] TO [svc_vireots_ro];
