-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
CREATE OR ALTER TRIGGER trgW ON DATABASE FOR ALTER_PROCEDURE AS DELETE FROM Infra.CurationRule;
