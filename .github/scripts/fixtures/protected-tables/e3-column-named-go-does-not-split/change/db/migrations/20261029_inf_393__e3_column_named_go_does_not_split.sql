DELETE c FROM (SELECT s.Id, s.GO FROM Infra.CurationRule s) AS c WHERE c.Id > 5;
