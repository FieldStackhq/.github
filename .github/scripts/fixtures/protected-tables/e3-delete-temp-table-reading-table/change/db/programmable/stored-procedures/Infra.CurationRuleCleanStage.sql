CREATE OR ALTER PROCEDURE Infra.CurationRuleCleanStage
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM #stage WHERE EXISTS (SELECT 1 FROM Infra.CurationRule c WHERE c.RuleId = #stage.RuleId);
END;
