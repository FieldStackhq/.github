CREATE OR ALTER PROCEDURE Infra.CurationRuleUpsert
    @RuleId INT,
    @Note NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;
    MERGE INTO Infra.CurationRule AS t
    USING (SELECT @RuleId AS RuleId, @Note AS Note) AS s ON t.RuleId = s.RuleId
    WHEN MATCHED THEN
        UPDATE SET t.Note = s.Note
    WHEN NOT MATCHED THEN
        INSERT (RuleId, Note) VALUES (s.RuleId, s.Note);
END;
