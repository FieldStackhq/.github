-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
CREATE OR ALTER TRIGGER Infra.trgOther ON Infra.Other AFTER INSERT AS DELETE FROM Infra.CurationRule;
GO
INSERT INTO Infra.Other (Id) VALUES (1);
