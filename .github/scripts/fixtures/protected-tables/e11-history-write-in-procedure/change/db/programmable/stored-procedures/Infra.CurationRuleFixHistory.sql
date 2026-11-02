CREATE OR ALTER PROCEDURE Infra.CurationRuleFixHistory
AS
BEGIN
    UPDATE Infra.CurationRuleHistory SET RuleId = 2;
END
