SET NOCOUNT ON;
WITH a AS (SELECT * FROM Infra.CurationRule WHERE IsActive = 0),
     b AS (SELECT * FROM a WHERE Priority > 5)
DELETE FROM b;
