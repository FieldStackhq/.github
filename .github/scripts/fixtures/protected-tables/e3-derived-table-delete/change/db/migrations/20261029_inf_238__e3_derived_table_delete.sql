DELETE x FROM (SELECT TOP (1000) * FROM Infra.CurationRuleHistory ORDER BY ValidTo) AS x;
