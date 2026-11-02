-- @no-transaction
EXEC sp_rename 'Infra.CurationRuleHistory.A', 'B', 'COLUMN';
EXEC sp_rename 'Infra.CurationRule.A', 'B', 'COLUMN';
