DELETE x FROM (SELECT * FROM (SELECT TOP (100) * FROM Infra.CurationRule ORDER BY RuleId) a) x;
