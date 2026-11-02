DECLARE @force BIT = 1;
IF @force = 0
    PRINT 'skipped'
ELSE DELETE FROM Infra.CurationRule;
