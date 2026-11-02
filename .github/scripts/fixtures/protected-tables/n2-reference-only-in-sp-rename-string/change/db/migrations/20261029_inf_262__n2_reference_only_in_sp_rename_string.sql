-- @no-transaction
EXEC sp_rename 'Infra.CurationRuleHistory.ValidTo', 'EndsAt', 'COLUMN';
