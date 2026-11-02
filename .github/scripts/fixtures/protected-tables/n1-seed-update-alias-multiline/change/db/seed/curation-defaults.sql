UPDATE r
SET r.Note = N'seeded'
FROM Infra.CurationRule r
WHERE r.RuleId = 1;
