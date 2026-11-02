DECLARE @new sysname = N'CurationRuleOld';
EXEC sp_rename N'Infra.CurationRule', @new;
