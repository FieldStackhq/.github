-- MIGRATION SAFETY: Infra.CurationRuleHistory -- Reviewed with Jeff, data is restored from the blob copy.
CREATE OR ALTER FUNCTION Infra.RuleHistoryOf (@id INT) RETURNS @t TABLE (RuleId INT) AS BEGIN
    INSERT INTO @t SELECT RuleId FROM Infra.CurationRuleHistory WHERE RuleId = @id;
    RETURN;
END;
