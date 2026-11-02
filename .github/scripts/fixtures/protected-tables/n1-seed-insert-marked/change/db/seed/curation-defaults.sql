-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
INSERT INTO Infra.CurationRule (RuleId, Note, IsActive)
VALUES (1, N'default', 1);
