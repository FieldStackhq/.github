CREATE OR ALTER PROCEDURE Infra.CurationRulePurgeHistory
    @Before DATETIME2
AS
BEGIN
    SET NOCOUNT ON
    DELETE FROM Infra.CurationRuleHistory WHERE ValidTo < @Before
END
