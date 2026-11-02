DECLARE @rc INT;
EXEC @rc = Infra.CurationRuleUpsert @RuleId = 1, @Note = N'seed';
