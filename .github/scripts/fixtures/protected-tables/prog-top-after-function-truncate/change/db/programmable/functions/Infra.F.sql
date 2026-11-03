-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
CREATE OR ALTER FUNCTION Infra.F () RETURNS INT AS BEGIN RETURN 1; END;
GO
TRUNCATE TABLE Infra.CurationRule;
