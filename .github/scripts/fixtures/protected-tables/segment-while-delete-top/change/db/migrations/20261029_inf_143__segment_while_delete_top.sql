WHILE 1 = 1
BEGIN
    DELETE TOP (5000) FROM Infra.CurationRuleHistory WHERE ValidTo < '2020-01-01';
    IF @@ROWCOUNT = 0 BREAK;
END;
