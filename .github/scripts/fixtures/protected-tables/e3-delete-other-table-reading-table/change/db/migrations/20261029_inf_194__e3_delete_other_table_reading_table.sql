DELETE FROM dbo.Widget WHERE RuleId IN (SELECT RuleId FROM Infra.CurationRule);
