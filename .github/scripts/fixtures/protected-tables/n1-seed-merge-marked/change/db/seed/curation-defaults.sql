-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
MERGE INTO Infra.CurationRule AS t
USING (VALUES (1, N'default')) AS s (RuleId, Note)
    ON t.RuleId = s.RuleId
WHEN NOT MATCHED THEN
    INSERT (RuleId, Note) VALUES (s.RuleId, s.Note);
