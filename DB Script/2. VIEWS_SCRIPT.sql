--------------------------------------------------------
--  File created - Monday-February-17-2025   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for View DICTONARYMASTER
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "DICTONARYMASTER" ("MASTER_ID", "OFFICECODE", "OFFICENAME", "OFFICETYPEID", "EMAIL", "MOBILENO", "TELEPHONENUMBER", "WEBADDRESS", "MASTER_ISACTIVE", "MASTER_CREATEDATE", "CREATEDBY", "MASTER_MODIFIEDDATE", "MODIFIEDBY", "DELETEDBY", "MASTER_ISDELETED", "PROFESSIONALTAX", "MASTER_DELETEDDATE", "PARENTOFFICEID", "DICOFFICETYPEID", "DICTIONARY_ID", "DICTIONARY_NAME", "DICTIONARY_CODE", "DICTIONARY_VALUE", "DICTIONARY_ISACTIVE", "DICTIONARY_CREATEDDATE", "DICTIONARY_MODIFIEDBY", "DICTIONARY_MODIFIEDDATE", "DICTIONARY_ISDELETED", "DICTIONARY_DELETEDBY", "DICTIONARY_DELETEDDATE", "DICTIONARY_NUMID") AS 
  SELECT 
            m.id AS master_id,
            m.officecode,
            m.officename,
            m.officetypeid,
            m.email,
            m.mobileno,
            m.telephonenumber,
            m.webaddress,
            m.isactive AS master_isactive,
            m.createddate AS master_createdate,
            m.createdby,
            m.modifieddate AS master_modifieddate,
            m.modifiedby,
            m.deletedby,
            m.isdeleted AS master_isdeleted,
            m.professionaltax,
            m.deleteddate AS master_deleteddate,
            m.parentofficeid,
            m.dicofficetypeid,
            d.id AS dictionary_id,
            d.name AS dictionary_name,
            d.code AS dictionary_code,
            d.value AS dictionary_value,
            d.isactive AS dictionary_isactive,
            d.createddate AS dictionary_createddate,
            d.modifiedby AS dictionary_modifiedby,
            d.modifieddate AS dictionary_modifieddate,
            d.isdeleted AS dictionary_isdeleted,
            d.deletedby AS dictionary_deletedby,
            d.deleteddate AS dictionary_deleteddate,
            d.numid AS dictionary_numid
        FROM Masteroffice m
        JOIN Dictionary d
        ON m.DicOfficeTypeId = d.Id
        WHERE m.Isdeleted = 0
;
--------------------------------------------------------
--  DDL for View OFFICE_DICTIONARY_VIEW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "OFFICE_DICTIONARY_VIEW" ("ID", "OFFICECODE", "OFFICENAME", "OFFICETYPEID", "EMAIL", "MOBILENO", "TELEPHONENUMBER", "WEBADDRESS", "ISACTIVE", "CREATEDDATE", "CREATEDBY", "MODIFIEDDATE", "MODIFIEDBY", "DELETEDBY", "ISDELETED", "PROFESSIONALTAX", "DELETEDDATE", "PARENTOFFICEID", "DICOFFICETYPEID", "VALUE") AS 
  SELECT mo."ID",mo."OFFICECODE",mo."OFFICENAME",mo."OFFICETYPEID",mo."EMAIL",mo."MOBILENO",mo."TELEPHONENUMBER",mo."WEBADDRESS",mo."ISACTIVE",mo."CREATEDDATE",mo."CREATEDBY",mo."MODIFIEDDATE",mo."MODIFIEDBY",mo."DELETEDBY",mo."ISDELETED",mo."PROFESSIONALTAX",mo."DELETEDDATE",mo."PARENTOFFICEID",mo."DICOFFICETYPEID", d.value
FROM masteroffice mo
JOIN dictionary d ON mo.dicofficetypeid = d.id
WHERE mo.officecode = SYS_CONTEXT('office_context', 'officeCode')
  AND (
        (d.value = 'Head Quarter' OR d.value IN ('RO Office', 'HV School', 'Head Quarter'))
     OR (d.value = 'RO Office' OR d.value IN ('RO Office', 'HV School'))
     OR (d.value = 'HV School' OR d.value = 'HV School')
     )
;
--------------------------------------------------------
--  DDL for View VM_MASTEREMPLOYEEROLE
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "VM_MASTEREMPLOYEEROLE" ("ID", "CODE", "ROLENAME", "EMPLOYEECODE", "LEVELBY", "ISACTIVE") AS 
  SELECT "ID","CODE","ROLENAME","EMPLOYEECODE","LEVELBY","ISACTIVE" 
FROM (
        SELECT v.* 
        FROM VM_MasterEmployeeRoleAll v
        ORDER BY LEVELBY DESC
     )
WHERE ROWNUM = 1
;
--------------------------------------------------------
--  DDL for View VM_MASTEREMPLOYEEROLEALL
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "VM_MASTEREMPLOYEEROLEALL" ("ID", "CODE", "ROLENAME", "EMPLOYEECODE", "LEVELBY", "ISACTIVE") AS 
  SELECT DISTINCT 
    MR.ID,   
    MR.Code,
    MR.Rolename, 
    SV.Employeecode, 
    MR.LEVELBY, 
    MR.IsActive
FROM  MASTERROLE MR
INNER JOIN MASTEREMPLOYEEROLE SV ON MR.ID = SV.RoleId
WHERE MR.ISActive = 1 AND EXPIREDDATE IS NULL
;
--------------------------------------------------------
--  DDL for View VW_MASTERROLEPERMISSION
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "VW_MASTERROLEPERMISSION" ("ROLEID", "ROLENAME", "ROLECODE", "PERMISSIONID", "PERMISSIONCODE", "ID", "ISACTIVE") AS 
  SELECT 
    RP.ROLEID, R.ROLENAME, R.Code ROLECODE, RP.PERMISSIONID, P.CODE PERMISSIONCODE, RP.ID, RP.ISACTIVE
FROM MASTERPERMISSION P
LEFT JOIN MASTERROLEPERMISSION RP ON P.ID = RP.PERMISSIONID
JOIN MASTERROLE R ON R.ID = RP.ROLEID
WHERE R.ISDELETED = 0 AND P.ISDELETED = 0 AND RP.ISDELETED = 0
;
