--------------------------------------------------------
--  File created - Monday-February-17-2025   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Procedure GETPAYBILLEMPLOYEEDATA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "GETPAYBILLEMPLOYEEDATA" (
    p_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        pe.id AS "employeeId", 
        pe.paybillMainId AS "paybillMainId", 
        pe.employeeCode AS "employeeCode",
        pe.employeeName AS "employeeName",
        pe.employeeDesignation "employeeDesignation", 
        pe.levelName AS "levelName",
        pe.numberOfPostSanctioned AS "numberOfPostSanctioned",
        pe.staffInPosition AS "staffInPosition" , 
        pe.totalDays AS "totalDays", 
        pe.totalPresentDays AS "totalPresentDays", 
        pe.basicPay AS "basicPay",
        pe.totalAllowance AS "totalAllowance", 
        pe.totalDeduction AS "totalDeduction",
        pe.finalAmount AS "finalAmount", 
        pe.dicStatusId AS "dicStatusId", 
       
        -- Allowances
        pa.deputationAllowance AS "deputationAllow", 
        pa.cashHandlingTreasuryAllowance AS "cashHandlingTreasuryAllow", 
        pa.highAltitudeAllowance AS "highAltitudeAllow", 
        pa.hardAreaAllowance AS "hardAreaAllow", 
        pa.islandSpecialDutyAllowance AS "islandSpecialDutyAllow", 
        pa.specialDutyAllowance AS "specialDutyAllow", 
        pa.toughLocationAllowance1 AS "toughLocationAllow1", 
        pa.toughLocationAllowance2 AS "toughLocationAllow2", 
        pa.toughLocationAllowance3 AS "toughLocationAllow3", 
        pa.secondShiftAllowance AS "secondShiftAllow", 
        pa.lsAndPcProjectKvs AS "lsAndPcProjectKVS", 
        pa.otherAllowance AS "otherAllowance", 
        pa.dressAllowance AS "dressAllowance",
        -- Deductions
        pd.licenceFeeOutsideAgency AS "licenceFeeOutsideAg", 
        pd.electricWaterChargesOutsideAgency AS "electricWaterChargesOutsideAg", 
        pd.coOpSociety AS "coOpSociety", 
        pd.convAdvInterestRecovery AS "convAdvInterestRec", 
        pd.cairInstallmentNo AS "cairInstallment", 
        pd.houseBuildingAdvanceInterest AS "hbaInterest", 
        pd.hbaiInstallmentNo AS "hbaiInstallment", 
        pd.primeMinisterCaresFund AS "pmCaresFund", 
        pd.otherRemittances AS "otherRemittances" , 
        pd.gpfRecovery AS "otherRemittances", 
        pd.gpfAdvanceRecovery AS "gpfAdvRecovery", 
        pd.gpfInstalmentNo AS "gpfInstallment", 
        pd.cpfRecoveryOwnShare AS "cpfOwnShare", 
        pd.cpfRecoveryMgtShare AS "cpfMgtShare", 
        pd.cpfAdvRecovery AS "cpfAdvRecovery", 
        pd.cpfInstallmentNo AS "cpfInstallment", 
        pd.kvsEmployeesWelfareScheme AS "kvsEmpWelfareScheme", 
        pd.hplRecovery AS "hplRecovery", 
        pd.licenceFeesKvsBuilding AS "licenceFeeKvsBldg", 
        pd.electricWaterCharges AS "electricWaterCharge", 
        pd.recOfOverPayment AS "recOfOverPayment", 
        pd.cghsRecovery AS "cghsRecovery", 
        pd.otherDeductions AS "otherDeductions"
    FROM paybillEmployee pe
    LEFT JOIN paybillAllowance pa ON pe.id = pa.paybillEmployeeId
    LEFT JOIN paybillDeduction pd ON pe.id = pd.paybillEmployeeId
    WHERE pe.paybillMainId = p_id;
END getPaybillEmployeeData;

/
--------------------------------------------------------
--  DDL for Procedure LOG_ERROR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "LOG_ERROR" (
    p_ProcedureName IN VARCHAR2,
    p_ErrorMessage  IN VARCHAR2,
    p_ErrorStack    IN CLOB DEFAULT NULL,
    p_ErrorParams   IN CLOB DEFAULT NULL
) AS
BEGIN
    INSERT INTO ErrorLog (ProcedureName, ErrorMessage, ErrorStack, ErrorParams)
    VALUES (p_ProcedureName, p_ErrorMessage, p_ErrorStack, p_ErrorParams);
    COMMIT;
END LOG_ERROR;

/
--------------------------------------------------------
--  DDL for Procedure TEST_SP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "TEST_SP" (
    p_empCode           IN VARCHAR2 DEFAULT NULL,
    p_dicofficetypeid    IN varchar2 DEFAULT NULL,     
    p_parentofficeid     IN varchar2 DEFAULT NULL,     
    p_pageno             IN INT DEFAULT NULL,          -- Default to page 1 if not provided
    p_pagesize           IN INT DEFAULT NULL,         -- Default to 10 records per page
    p_searchtext         IN VARCHAR2 DEFAULT NULL,
    p_cursor             OUT SYS_REFCURSOR
) AS
    P_OFFICECODE  INT;
    v_value       VARCHAR2(50);
    v_params      CLOB := 'Param_name:' || p_empCode;

BEGIN
    -- Ensure employee code is provided
    IF p_empCode IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employee code cannot be null');
    END IF;

    -- Get office code for the provided employee code
    BEGIN
        SELECT e.officeid INTO P_OFFICECODE
        FROM MASTEREMPLOYEE e 
        WHERE e.EmployeeCode = p_empCode AND e.Isdeleted=0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Employee code not found.');
    END;

    -- Get office type ID for the provided office code
    BEGIN
        SELECT dicofficetypeid INTO v_value 
        FROM masteroffice 
        WHERE id = P_OFFICECODE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Office not found.');
    END;

    -- If the office type ID is 1, nullify the office code
    IF v_value = 1 THEN
        P_OFFICECODE := NULL;
    END IF;

    DBMS_OUTPUT.put_line('Office Code: ' || P_OFFICECODE);
    DBMS_OUTPUT.put_line('p_dicofficetypeid: ' || p_dicofficetypeid);
    -- Open the cursor with the query for pagination using CTE
    OPEN p_cursor FOR
    WITH CTE AS 
    (
        SELECT 
            ms.Id AS "id",
            ms.officecode AS "officeCode", 
            ms.officename AS "officeName",
            ms.OfficeCode || ' - ' || ms.OfficeName AS "displayName",
            ms.officetypeid AS "officetypeid",
            ms.parentofficeid AS "parentofficeid",
            ms.dicofficetypeid AS "dicofficetypeid",
            mo1.officename AS "parentoffice",
            DIC.VALUE AS "officetype",
            ma.address1 AS "address1", 
            ma.address2 AS "address2", 
            ma.stateid AS "stateid",
            ma.cityid AS "cityid",
            ma.pin AS "PinNo",
            ms.email AS "email",
            ms.mobileno AS "mobile",
            ms.telephonenumber AS "tno", 
            mct.name AS "name",
            mst.statename AS "statename",
            ms.webaddress AS "webaddress", 
            ms.professionaltax AS "professionaltax",
            ms.createdby,
            ms.modifiedby,
            ms.IsDeleted,
            ms.Deletedby,
            ms.IsActive AS "IsActive",
            ROW_NUMBER() OVER (ORDER BY DIC.NumId, Mst.StateName, Ms.OfficeName) AS rownums
        FROM MasterOffice ms
        LEFT JOIN MasterAddress ma ON ms.ID = ma.tablekey AND ma.TableName = 'MasterOffice'
        LEFT JOIN MasterSTATE Mst ON ma.Stateid = mst.ID
        LEFT JOIN MASTERCITY MCT ON ma.cityid = mct.ID
        LEFT JOIN Dictionary DIC ON ms.DicOfficeTypeId = DIC.NumId AND Dic.Code = 'OFFICE_TYPE'
        LEFT JOIN MASTEROFFICE MO1 ON MO1.Id = ms.parentofficeid
        WHERE ms.IsDeleted = 0 AND ms.IsActive = 1
            AND 
            (
                -- If p_parentofficeID is provided, match ID or ParentOfficeID
                (p_parentofficeid IS NOT NULL AND (ms.ID = p_parentofficeid OR ms.parentofficeid = p_parentofficeid))  
                -- If p_parentofficeID is NULL, apply filter on officetypeid
                OR (p_parentofficeid IS NULL AND ms.dicofficetypeid = p_dicofficetypeid)
            )
             -- AND (MS.Id = NVL(p_officecode, MS.Id) )  
             AND 
                (p_searchtext IS NULL OR LOWER(ms.officename) LIKE '%' || LOWER(p_searchtext) || '%' 
                OR LOWER(ms.officecode) LIKE '%' || LOWER(p_searchtext) || '%')  -- Optional search filter
    )
    SELECT (SELECT COUNT(1) FROM CTE) AS "totalCount", CTE.*
    FROM CTE
    WHERE CTE.rownums BETWEEN ((p_pageno - 1) * p_pagesize + 1) AND (p_pageno * p_pagesize)
    ORDER BY CTE.rownums;

    DBMS_OUTPUT.put_line('pARENT Code: ' || p_parentofficeid);

EXCEPTION
    WHEN OTHERS THEN
        -- Log error if any exception occurs
        LOG_ERROR('usp_Masteroffice_getall', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
        RAISE;
END Test_SP;

/
--------------------------------------------------------
--  DDL for Procedure USP_CORE_PORTAL_USER_LOGIN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "USP_CORE_PORTAL_USER_LOGIN" 
(
    p_employeecode IN VARCHAR2,
    p_password IN VARCHAR2,
    p_roleid IN NUMBER DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
)
AS
    u_id NUMBER;
    u_roleid NUMBER;
    u_rolename VARCHAR2(100);
    u_rolecode VARCHAR2(100); -- Specify a length for the VARCHAR2 variable
    v_params CLOB := 'Param_name:' || p_employeecode;

BEGIN

    IF p_password IS NOT NULL THEN    
        SELECT E.Id, R.Id RoleId, R.RoleName, R.Code RoleCode
        INTO u_id, u_roleid, u_rolename, u_rolecode
        FROM masteremployee E 
        INNER JOIN masteremployeerole ER ON E.EmployeeCode = ER.EmployeeCode
        INNER JOIN masterrole R ON ER.RoleId = R.Id
        WHERE E.employeecode = p_employeecode
          AND E.password = p_password
          AND ROWNUM = 1; -- Return only one record

    ELSIF p_roleid IS NOT NULL THEN    
        SELECT E.Id, R.Id RoleId, R.RoleName, R.Code RoleCode
        INTO u_id, u_roleid, u_rolename, u_rolecode
        FROM masteremployee E
        INNER JOIN masteremployeerole ER ON E.EmployeeCode = ER.EmployeeCode
        INNER JOIN masterrole R ON ER.RoleId = R.Id
        WHERE E.EmployeeCode = p_employeecode
          AND R.Id = p_roleid
          AND ROWNUM = 1;
    END IF;    

    OPEN p_cursor FOR
        SELECT 
            U.Id,
            U.EmployeeCode,
            O.Id as "OfficeId",
            O.OfficeCode,
            O.OfficeName,
            U.FirstName,
            U.LastName,
            U.FullName AS UserName,
            U.DesignationId,
            U.BasicPay,
            U.PanNo,
            u_roleid AS RoleId,                      -- Add RoleId
            u_rolename AS RoleName,                  -- Add RoleName
            u_rolecode AS RoleCode,                  -- Add RoleCode
            U.DateOfBirth,
            U.Mobile,
            U.Email,
            NVL(OT.Type, 'HQ') AS OfficeType
        FROM MasterEmployee U               
        LEFT JOIN MasterOffice O ON U.OfficeId = O.Id
        LEFT JOIN MasterOfficeType OT ON O.OfficeTypeId = OT.Id
        WHERE U.Id = u_id;
 EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('usp_core_portal_user_login', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_CORE_PORTAL_USER_SWITCH_LOGIN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "USP_CORE_PORTAL_USER_SWITCH_LOGIN" (
    p_employeecode IN VARCHAR2,
    p_roleid IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
)
AS
v_params CLOB := 'Param_name:' || p_employeecode;
BEGIN
     OPEN p_cursor FOR

    SELECT 
        U.Id,
        U.EmployeeCode,
        O.Id as "OfficeId",
        O.OfficeCode,
        O.OfficeName,
        U.FirstName,
        U.LastName,
        U.FullName AS UserName,
        U.DesignationId,
        U.BasicPay,
        U.PanNo,
        R.Id AS RoleId,             -- Add RoleId
        R.RoleName,                   -- Add RoleName
        R.Code RoleCode,
        U.DateOfBirth,
        U.Mobile,
        U.Email,
        '' OfficeType
    FROM VM_MASTEREMPLOYEEROLEALL R
    JOIN MASTEREMPLOYEE U    ON U.EmployeeCode = R.EmployeeCode
    LEFT JOIN MasterOffice O ON U.OfficeId = O.Id
    WHERE R.EmployeeCode = p_employeecode   
          AND R.ID = p_roleid    
    FETCH FIRST ROW ONLY; -- Return only one record
EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('usp_core_portal_user_switch_login', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_DICTIONARY_CRUD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_DICTIONARY_CRUD" (
    p_operation IN VARCHAR2,
    p_id IN NUMBER DEFAULT NULL,
    p_Name IN VARCHAR2 DEFAULT NULL,
    p_Code IN VARCHAR2 DEFAULT NULL,
    p_VALUE IN VARCHAR2 DEFAULT NULL,
    p_NumId IN VARCHAR2 DEFAULT NULL, 
    p_IsDeleted IN NUMBER DEFAULT NULL,
    p_CreatedBy IN VARCHAR2 DEFAULT NULL, 
    p_cursor OUT SYS_REFCURSOR
)
AS
v_params CLOB := 'Param_name:' || p_operation;
BEGIN
    IF p_operation = 'INSERT' THEN
            INSERT INTO Dictionary (Name, Code, VALUE, NumId, CreatedBy, CreatedDate, IsActive, IsDeleted)
            VALUES (p_Name, p_Code, p_VALUE, p_NumId, p_CreatedBy, SYSDATE, 1, 0);
            COMMIT;

    ELSIF p_operation = 'UPDATE' THEN
        UPDATE Dictionary SET Name = p_Name, Code = p_Code, VALUE = p_VALUE, NumId = p_NumId, IsDeleted = p_IsDeleted,
                              ModifiedBy = p_CreatedBy, ModifiedDate = SYSDATE 
        WHERE ID = p_id;
        COMMIT;

    ELSIF p_operation = 'DELETE' THEN
        UPDATE Dictionary SET IsDeleted = 1, DeletedBy = p_CreatedBy, DeletedDate = SYSDATE, IsActive = 0
        WHERE ID = p_id;
        COMMIT; 

    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Invalid operation specified');
    END IF;

 EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('usp_Dictionary_CRUD', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_DICTIONARY_GET
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_DICTIONARY_GET" (
    p_operation IN VARCHAR2, 
    p_id IN NUMBER DEFAULT NULL, 
    p_Code IN VARCHAR2 DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
)
AS
v_params CLOB := 'Param_name:' || p_operation;
BEGIN 
    IF p_operation = 'ALL' THEN
        OPEN p_cursor FOR
        SELECT * FROM Dictionary WHERE IsDeleted = 0;

    ELSIF p_operation = 'CODE' THEN
        OPEN p_cursor FOR
        SELECT * FROM Dictionary WHERE Code = p_Code AND IsDeleted = 0;

    ELSIF p_operation = 'ID' THEN
        OPEN p_cursor FOR
        SELECT * FROM Dictionary WHERE ID = p_id AND IsDeleted = 0;

    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Invalid operation specified');
    END IF;

    EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('usp_Dictionary_GET', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_EMP_TEMPTABLE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "USP_EMP_TEMPTABLE" 
AS
BEGIN
    -- Drop the table if it exists (check for existence first)
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE TEMP_TABLE';
    EXCEPTION
        WHEN OTHERS THEN
            -- If the table does not exist, just ignore the error
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;

    -- Create the TEMP_TABLE with filtered data
    EXECUTE IMMEDIATE '
        CREATE GLOBAL TEMPORARY TABLE TEMP_TABLE (
            ID NUMBER,
            OFFICEID VARCHAR2(100),
            EMPLOYEECODE VARCHAR2(100),
            FIRSTNAME VARCHAR2(100),
            MIDDLENAME VARCHAR2(100),
            LASTNAME VARCHAR2(100),
            DESIGNATIONID NUMBER,
            GENDER CHAR(1),
            DATEOFBIRTH DATE,
            LEVELID NUMBER,
            BASICPAY NUMBER,
            PANNO VARCHAR2(50),
            PASSWORD VARCHAR2(100),
            FULLNAME VARCHAR2(200),
            EMAIL VARCHAR2(100),
            MOBILE VARCHAR2(15),
            DATEOFJOINING DATE,
            CURRENTDESIGNATIONDATE DATE,
            ISHANDICAP CHAR(1),
            ISALLOTMENTQUARTER CHAR(1),
            TYPEOFQUARTER VARCHAR2(100),
            ISACTIVE CHAR(1),
            LASTINCREMENTDATE DATE,
            NEXTCREMENTDATE DATE,
            ROLEID NUMBER,
            ISADDITIONHRA CHAR(1),
            ADDITIONALHRACITY VARCHAR2(100),
            SCHEMETYPE VARCHAR2(50),
            ENTITLEFORDOUBLETA CHAR(1),
            DOUBLETA NUMBER,
            CREATEDDATE DATE,
            CREATEDBY VARCHAR2(100),
            MODIFIEDDATE DATE,
            MODIFIEDBY VARCHAR2(100),
            ISDELETED CHAR(1),
            DELETEDBY VARCHAR2(100),
            ROWNUMS NUMBER
        ) ON COMMIT PRESERVE ROWS';
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_GETEMPLOYEESALARYSLIPDATA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_GETEMPLOYEESALARYSLIPDATA" (
    p_year IN NUMBER,
    p_month IN VARCHAR2 DEFAULT NULL,
    p_officeCode IN VARCHAR2 DEFAULT NULL,
    p_loginEmployeeCode  IN VARCHAR2 DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        pm.officeCode AS "officeCode",
        pm.Month AS "month",
        pm.year AS "year",
        pe.id AS "Id", 
        pe.paybillMainId AS "paybillMainId", 
        pe.employeeCode AS "employeeCode",
        pe.employeeName AS "employeeName",
        mb.ACCOUNTNUMBER as "accountNumber",
        pe.employeeDesignation "employeeDesignation", 
        pe.levelName AS "levelName",
        pe.numberOfPostSanctioned AS "numberOfPostSanctioned",
        pe.staffInPosition AS "staffInPosition" , 
        pe.TotalDays AS "totalDays",
        pe.totalPresentDays AS "totalPresentDays", 
        pe.basicPay AS "basicPay",
        pe.totalAllowance AS "totalAllowance", 
        pe.totalDeduction AS "totalDeduction",
        pe.finalAmount AS "finalAmount", 
        pe.DicStatusId AS "DicStatusId",
        dd.Value AS "DicStatus",

         pe.DICSTATUSId AS "dicstatusid",
                    CASE
                        WHEN pe.DICSTATUSId = 5 THEN 'Approved'
                        WHEN pe.DICSTATUSId = 2 THEN 'Rejected'
                        WHEN pe.DICSTATUSId = 1 THEN 'Pending'
                        ELSE ''
                    END AS "status",
                    CASE
                        WHEN pe.DICHOSTATUSID = 5 THEN 'Approved'
                        WHEN pe.DICHOSTATUSID = 2 THEN 'Rejected'
                        WHEN pe.DICHOSTATUSID = 1 THEN 'Pending'
                        ELSE ''
                    END AS "hoStatus",
                    CASE
                        WHEN pe.DICROSTATUSID = 5 THEN 'Approved'
                        WHEN pe.DICROSTATUSID = 2 THEN 'Rejected'
                        WHEN pe.DICROSTATUSID = 1 THEN 'Pending'
                        ELSE ''
                    END AS "roStatus",


        -- Allowances
        pa.Id AS "PayBillAllowanceId",
        pa.PayBillEmployeeId AS "payBillEmployeeId",
        pa.deputationAllowance AS "deputationAllowance", 
        pa.cashHandlingTreasuryAllowance AS "cashHandlingTreasuryAllowance", 
        pa.highAltitudeAllowance AS "highAltitudeAllowance", 
        pa.hardAreaAllowance AS "hardAreaAllowance", 
        pa.islandSpecialDutyAllowance AS "islandSpecialDutyAllowance", 
        pa.specialDutyAllowance AS "specialDutyAllowance", 
        pa.toughLocationAllowance1 AS "toughLocationAllowance1", 
        pa.toughLocationAllowance2 AS "toughLocationAllowance2", 
        pa.toughLocationAllowance3 AS "toughLocationAllowance3", 
        pa.secondShiftAllowance AS "secondShiftAllowance", 
        pa.lsAndPcProjectKvs AS "lsAndPcProjectKvs", 
        pa.otherAllowance AS "otherAllowance", 
        pa.dressAllowance AS "dressAllowance",
        pa.DEARNESSALLOWANCE as "dearnessAllowance",
        pa.TRANSPORTALLOWANCE as "transportAllowance",
        pa.DAONTRANSPORTALL0WANCE AS "daOnTransportAllowance",
        -- Deductions
        pd.Id AS "PayBillDeductionId",
        pd.licenceFeeOutsideAgency AS "licenceFeeOutsideAg", 
        pd.electricWaterChargesOutsideAgency AS "electricWaterChargesOutsideAg", 
        pd.coOpSociety AS "coOpSociety", 
        pd.convAdvInterestRecovery AS "convAdvInterestRec", 
        pd.cairInstallmentNo AS "cairInstallment", 
        pd.houseBuildingAdvanceInterest AS "hbaInterest", 
        pd.hbaiInstallmentNo AS "hbaiInstallment", 
        pd.primeMinisterCaresFund AS "pmCaresFund", 
        pd.otherRemittances AS "otherRemittances" , 
        pd.gpfRecovery AS "gpfRecovery", 
    
        pd.gpfAdvanceRecovery AS "gpfAdvRecovery", 
        pd.gpfInstalmentNo AS "gpfInstallment", 
        pd.cpfRecoveryOwnShare AS "cpfOwnShare", 
        pd.cpfRecoveryMgtShare AS "cpfMgtShare", 
        pd.cpfAdvRecovery AS "cpfAdvRecovery", 
        pd.cpfInstallmentNo AS "cpfInstallment", 
        pd.kvsEmployeesWelfareScheme AS "kvsEmpWelfareScheme", 
        pd.hplRecovery AS "hplRecovery", 
        pd.licenceFeesKvsBuilding AS "licenceFeeKvsBldg", 
        pd.electricWaterCharges AS "electricWaterCharge", 
        pd.recOfOverPayment AS "recOfOverPayment", 
        pd.cghsRecovery AS "cghsRecovery", 
        pd.otherDeductions AS "otherDeductions",
        pd.INCOMETAX as "incomeTax"
    FROM PaybillMain pm
     Left JOIN  paybillEmployee pe ON pm.ID=pe.paybillmainId
    LEFT JOIN paybillAllowance pa ON pe.id = pa.paybillEmployeeId
    LEFT JOIN paybillDeduction pd ON pe.id = pd.paybillEmployeeId
    LEFT JOIN Masterbank mb On pe.EmployeeCode=mb.EmployeeCode
    LEFT JOIN Dictionary dd ON pe.DicStatusId = dd.NumId AND dd.Code='PAYBILL_STATUS'
    WHERE pm.year = p_year And pm.month=p_month And pm.officeCode=p_officeCode and pe.EmployeeCode=p_loginEmployeeCode;
END usp_getEmployeeSalarySlipData;

/
--------------------------------------------------------
--  DDL for Procedure USP_GETMASTEREMPLOYEEROLE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_GETMASTEREMPLOYEEROLE" (
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT * FROM VM_MasterEmployeeRole;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_GETMASTEREMPLOYEEROLEALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_GETMASTEREMPLOYEEROLEALL" (
    p_EmployeeCode IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT * --Name, ID, EmployeeCode, LevelBy, IsActive
    FROM VM_MasterEmployeeRoleAll
    WHERE EmployeeCode = p_EmployeeCode;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_GETPAYBILLEMPLOYEEDATA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_GETPAYBILLEMPLOYEEDATA" (
    p_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        pe.id AS "id", 
        pe.paybillMainId AS "payBillMainId", 
        pe.employeeCode AS "employeeCode",
        pe.employeeName AS "employeeName",
        pe.employeeDesignation "employeeDesignation", 
        pe.levelName AS "levelName",
        pe.numberOfPostSanctioned AS "numberOfPostSanctioned",
        pe.staffInPosition AS "staffInPosition" , 
        pe.TotalDays AS "totalDays",
        pe.totalPresentDays AS "totalPresentDays", 
        pe.basicPay AS "basicPay",
        pe.totalAllowance AS "totalAllowance", 
        pe.totalDeduction AS "totalDeduction",
        pe.finalAmount AS "finalAmount",
        dd.Value AS "dicStatus",
        
        pe.DICSTATUSId AS "dicStatusId",
        CASE
                        WHEN pe.DICSTATUSId = 5 THEN 'Approved'
                        WHEN pe.DICSTATUSId = 2 THEN 'Rejected'
                        WHEN pe.DICSTATUSId = 1 THEN 'Pending'
                        ELSE ''
                    END AS "status",
                    CASE
                        WHEN pe.DICHOSTATUSID = 5 THEN 'Approved'
                        WHEN pe.DICHOSTATUSID = 2 THEN 'Rejected'
                        WHEN pe.DICHOSTATUSID = 1 THEN 'Pending'
                        ELSE ''
                    END AS "hoStatus",
                    CASE
                        WHEN pe.DICROSTATUSID = 5 THEN 'Approved'
                        WHEN pe.DICROSTATUSID = 2 THEN 'Rejected'
                        WHEN pe.DICROSTATUSID = 1 THEN 'Pending'
                        ELSE ''
                    END AS "roStatus",

         pe.HOCOMMENTS AS "hoComments", 
         pe.ROCOMMENTS AS "roComments", 
         pe.COMMENTS AS "comments",
        -- Allowances
        pa.Id AS "payBillAllowanceId",
        pa.PayBillEmployeeId AS "payBillEmployeeId",
        pa.deputationAllowance AS "deputationAllowance", 
        pa.DEARNESSALLOWANCE AS dearnessAllowance,  
        pa.TRANSPORTALLOWANCE AS transportAllowance,  
        pa.DAONTRANSPORTALL0WANCE AS daOnTransportAllowance,  
        pa.HOUSERENTALLOWANCEDHRA AS houseRentAllowanceDhra,  
        NVL(pa.ADDITIONALHRA,0) AS "additionalHra",
        pa.NPSMGTSHARE AS npsMgtShare,  
        pa.CPFMGTSHARE AS cpfMgtShare ,
        pa.cashHandlingTreasuryAllowance AS "cashHandlingTreasuryAllowance", 
        pa.highAltitudeAllowance AS "highAltitudeAllowance", 
        pa.hardAreaAllowance AS "hardAreaAllowance", 
        pa.islandSpecialDutyAllowance AS "islandSpecialDutyAllowance", 
        pa.specialDutyAllowance AS "specialDutyAllowance", 
        pa.toughLocationAllowance1 AS "toughLocationAllowance1", 
        pa.toughLocationAllowance2 AS "toughLocationAllowance2", 
        pa.toughLocationAllowance3 AS "toughLocationAllowance3", 
        pa.secondShiftAllowance AS "secondShiftAllowance", 
        pa.lsAndPcProjectKvs AS "lsAndPcProjectKvs", 
        pa.otherAllowance AS "otherAllowance", 
        pa.dressAllowance AS "dressAllowance",
        -- Deductions
        pd.Id AS "payBillDeductionId",
        pd.INCOMETAX AS incomeTax,  
        pd.PROFESSIONALTAX AS professionalTax,
        pd.licenceFeeOutsideAgency AS "licenceFeeOutsideAg", 
        pd.electricWaterChargesOutsideAgency AS "electricWaterChargesOutsideAg", 
        pd.NPSOWNSHARE AS npsOwnShare,  
        pd.NPSMGTSHARE AS npsMgtShare,
        pd.coOpSociety AS "coOpSociety", 
        pd.convAdvInterestRecovery AS "convAdvInterestRec", 
        pd.cairInstallmentNo AS "cairInstallment", 
        pd.houseBuildingAdvanceInterest AS "hbaInterest", 
        pd.hbaiInstallmentNo AS "hbaiInstallment", 
        pd.primeMinisterCaresFund AS "pmCaresFund", 
        pd.otherRemittances AS "otherRemittances" , 
        pd.gpfRecovery AS "gpfRecovery", 
        pd.gpfAdvanceRecovery AS "gpfAdvRecovery", 
        pd.gpfInstalmentNo AS "gpfInstallment", 
        pd.cpfRecoveryOwnShare AS "cpfOwnShare", 
        pd.cpfRecoveryMgtShare AS "cpfMgtShare", 
        pd.cpfAdvRecovery AS "cpfAdvRecovery", 
        pd.cpfInstallmentNo AS "cpfInstallment", 
        pd.kvsEmployeesWelfareScheme AS "kvsEmpWelfareScheme", 
        pd.hplRecovery AS "hplRecovery", 
        pd.licenceFeesKvsBuilding AS "licenceFeeKvsBldg", 
        pd.electricWaterCharges AS "electricWaterCharge", 
        pd.recOfOverPayment AS "recOfOverPayment", 
        pd.cghsRecovery AS "cghsRecovery", 
        pd.otherDeductions AS "otherDeductions"
    FROM paybillEmployee pe
    LEFT JOIN paybillAllowance pa ON pe.id = pa.paybillEmployeeId
    LEFT JOIN paybillDeduction pd ON pe.id = pd.paybillEmployeeId
    LEFT JOIN Dictionary dd ON pe.DicStatusId = dd.NumId AND dd.Code='PAYBILL_STATUS'
    WHERE pe.paybillMainId = p_id;
END usp_getPaybillEmployeeData;

/
--------------------------------------------------------
--  DDL for Procedure USP_INSERTERRORLOG
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_INSERTERRORLOG" (
    p_errormessage    IN VARCHAR2 DEFAULT NULL,
    p_errorstack      IN CLOB,
    p_errorparams     IN CLOB,
    p_username        IN VARCHAR2 DEFAULT NULL,
    p_methodname      IN VARCHAR2 DEFAULT NULL
) AS
BEGIN
    INSERT INTO ErrorLog (
        ERRORMESSAGE,
        ERRORSTACK,
        ERRORPARAMS,
        ERRORDATE,
        USERNAME,
        METHODNAME
    ) 
    VALUES (
        p_ERRORMESSAGE,
        p_ERRORSTACK,
        p_ERRORPARAMS,
        SYSTIMESTAMP,
        p_USERNAME,
        p_METHODNAME
    );

    COMMIT; 
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error inserting into ErrorLog: ' || SQLERRM);
END USP_InsertErrorLog;

/
--------------------------------------------------------
--  DDL for Procedure USP_LEAVEAPPROVEREJECT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_LEAVEAPPROVEREJECT" (
    p_id IN NUMBER,
    p_approveorreject IN NUMBER,
    p_comments IN VARCHAR2,
    p_actionby IN VARCHAR2
)
AS
    v_dic_status_id NUMBER;
    v_current_status NUMBER;
    v_params CLOB := 'Param_name:' || p_id;

BEGIN
    -- Check the current status of the leave entry
    SELECT DicLeaveStatusId 
    INTO v_current_status
    FROM LeaveEntry
    WHERE Id = p_id;

    -- If already approved (status 5), prevent update
    IF v_current_status = 5 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Leave has already been approved and cannot be modified.');
    END IF;

    -- Get the Dictionary ID for the new status (Approved/Rejected)
    SELECT NUMID
    INTO v_dic_status_id
    FROM Dictionary
    WHERE Code = 'LEAVEENTRY_STATUS'
      AND UPPER(Value) = UPPER(CASE 
                        WHEN p_approveorreject = 1 THEN 'Approved'
                        WHEN p_approveorreject = 0 THEN 'Rejected'
                      END);

    -- Perform the update
    UPDATE LeaveEntry
    SET DicLeaveStatusId = v_dic_status_id,
        Comments = p_comments,
        StatusChangedBy = p_actionby,
        ModifiedDate = SYSDATE
    WHERE Id = p_id;

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        LOG_ERROR('usp_LeaveApproveReject', 'Dictionary entry not found', DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
        RAISE_APPLICATION_ERROR(-20003, 'Invalid status. Please check the Dictionary table.');

    WHEN OTHERS THEN
        LOG_ERROR('usp_LeaveApproveReject', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
        RAISE;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_LEAVEENTRY_APPROVEREJECT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_LEAVEENTRY_APPROVEREJECT" (
    p_id IN NUMBER,
    p_approveorreject IN NUMBER,
    p_comments IN VARCHAR2,
    p_actionby IN VARCHAR2
)
AS
    v_dic_status_id NUMBER;
    v_current_status NUMBER;
    v_LeaveMainId NUMBER;
    v_params CLOB := 'Param_name:' || p_id;
    v_count NUMBER;

BEGIN
    -- Check the current status of the leave entry
    SELECT l.DicLeaveStatusId, l.LEAVEENTRYMAINID
    INTO v_current_status, v_LeaveMainId
    FROM LeaveEntry l 
    JOIN LeaveEntryMain m ON m.Id = l.LEAVEENTRYMAINID
    WHERE l.Id = p_id;
    

    -- If already approved (status 5), prevent update
    IF v_current_status = 5 THEN
        RAISE_APPLICATION_ERROR(-20002, 'already been approved and cannot be modified.');
    END IF;

    -- Get the Dictionary ID for the new status (Approved/Rejected)
    SELECT NUMID
    INTO v_dic_status_id
    FROM Dictionary
    WHERE Code = 'LEAVEENTRY_STATUS'
         AND NumId = (CASE WHEN p_approveorreject = 1 THEN 5 ELSE 2 END); 
      /*   
      AND UPPER(Value) = UPPER(CASE 
                        WHEN p_approveorreject = 1 THEN 'Approved'
                        WHEN p_approveorreject = 0 THEN 'Rejected'
                      END);
    */

    -- Perform the update
    UPDATE LeaveEntry
    SET DicLeaveStatusId = v_dic_status_id,
        Comments = p_comments,
        StatusChangedBy = p_actionby,
        ModifiedDate = SYSDATE
    WHERE Id = p_id;


    --IF NOT EXISTS (SELECT v.ID FROM LeaveEntry v WHERE v.LEAVEENTRYMAINID = v_LeaveMainId AND v.dicleavestatusid < 5); 
    SELECT COUNT(*)
    INTO v_count
    FROM LeaveEntry
    WHERE LEAVEENTRYMAINID = v_LeaveMainId
    AND DicLeaveStatusId < 5;  -- Check if any are pending/rejected

    -- If no pending records exist, call PayBill insertion procedure
    IF v_count = 0 THEN
        UPDATE LEaveentryMain SET DICSTATUSID = 5 -- Approved
        WHERE Id = v_LeaveMainId;        
        
        USP_PAYBILL_UPSERTEMPLOYEE_LEAVES(v_LeaveMainId, p_actionby);
    END IF;


EXCEPTION
    WHEN OTHERS THEN
        LOG_ERROR('usp_LeaveApproveReject', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
        RAISE;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_LEAVEENTRY_BULK_APPROVE_REJECT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_LEAVEENTRY_BULK_APPROVE_REJECT" (
    p_json_input IN CLOB,        -- JSON array of objects as input
    p_actionby IN VARCHAR2       -- User performing the action
) AS
    -- Declare variables
    v_dic_status_id NUMBER;      -- Variable to store the Dictionary ID for "LEAVE_STATUS"
    v_params CLOB := 'Param_name:' || p_json_input;
BEGIN
    -- Use JSON_TABLE to parse the JSON array into relational rows
    FOR r IN (
        SELECT jt.Id AS id,
               jt.Comments AS comments,
               jt.approveOrReject AS approveOrReject
        FROM JSON_TABLE(
            p_json_input,
            '$.input[*]' -- Parse each element in the JSON array
            COLUMNS (
                Id             NUMBER PATH '$.id',
                Comments       VARCHAR2(500) PATH '$.comments',
                approveOrReject NUMBER PATH '$.approveOrReject'
            )
        ) jt
    ) LOOP
        BEGIN
            -- Determine the Dictionary ID based on approveOrReject
            SELECT Id
            INTO v_dic_status_id
            FROM Dictionary
            WHERE Code = 'LEAVE_STATUS'
              AND UPPER(Value) = UPPER(CASE 
                    WHEN r.approveOrReject = 1 THEN 'Approved' 
                    ELSE 'Rejected' 
                  END);

            -- Update the LeaveEntry table
            UPDATE LeaveEntry
            SET DICLEAVESTATUSID = v_dic_status_id,
                Comments = r.comments,
                ModifiedDate = SYSDATE,
                StatusChangedBy = p_actionby
            WHERE Id = r.id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Handle case where Dictionary entry is not found
                RAISE_APPLICATION_ERROR(-20001, 'LEAVE_STATUS not found in Dictionary table for ID: ' || r.id);

            WHEN OTHERS THEN
                -- Log and re-raise unexpected errors
                ROLLBACK;
                RAISE;
        END;
    END LOOP;

    -- Commit the changes
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback in case of any unexpected errors
        LOG_ERROR('usp_leaveentry_bulk_approve_reject', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
        ROLLBACK;
        RAISE;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_LEAVEENTRY_BULK_UPSERT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_LEAVEENTRY_BULK_UPSERT" (
    p_json_input IN CLOB, -- JSON array of objects as input
    p_actionby IN VARCHAR2,
    p_officecode IN VARCHAR2
) AS
    v_main_id NUMBER; -- Variable to store LeaveEntryMain ID
    v_leave_status_id NUMBER;
    v_params CLOB := 'Param_name:' || p_json_input;
BEGIN

    BEGIN
        SELECT NUMID INTO v_leave_status_id
        FROM Dictionary
        WHERE Code = 'LEAVEENTRY_STATUS' AND NUMID = 1
        FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Pending leave status not found in Dictionary.');
    END;
    -- Process each record in the JSON input
    FOR r IN (
        SELECT jt.Id AS id,
               jt.EmployeeCode AS employeecode,
               jt.OfficeCode AS officecode,
               jt.Month AS month,
               jt.Year AS year,
               jt.DicLeaveTypeId AS dicleavetypeid,
               jt.LeaveDays AS leavedays
        FROM JSON_TABLE(
            p_json_input,
            '$[*]' -- Parse each element in the JSON array
            COLUMNS (
                Id              NUMBER       PATH '$.Id',
                EmployeeCode    VARCHAR2(50) PATH '$.EmployeeCode',
                OfficeCode    VARCHAR2(50) PATH '$.OfficeCode',
                Month           VARCHAR2(10) PATH '$.Month',
                Year            VARCHAR2(10) PATH '$.Year',
                DicLeaveTypeId  NUMBER(5,1)  PATH '$.DicLeaveTypeId',
                LeaveDays       NUMBER(10,1)       PATH '$.LeaveDays'
            )
        ) jt 
    ) LOOP
        -- Attempt to find a matching LeaveEntryMain record
        BEGIN
            SELECT ID INTO v_main_id
            FROM LeaveEntryMain
            WHERE OfficeCode = COALESCE(r.officecode, p_officecode) AND Month = r.month AND Year = r.year
            FETCH FIRST 1 ROWS ONLY;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                IF v_main_id IS NULL THEN
                    -- Insert a new LeaveEntryMain record if no match is found
                    INSERT INTO LeaveEntryMain (
                        OfficeCode,
                        Month,
                        Year,
                        DicStatusId,
                        CreatedDate,
                        CreatedBy
                    ) VALUES (
                        COALESCE(r.officecode, p_officecode),
                        r.month,
                        r.year,
                        v_leave_status_id,
                        SYSDATE,
                        p_actionby
                    )
                    RETURNING ID INTO v_main_id;
                END IF;
        END;

        -- Check if the ID is 0, indicating an insert
        IF r.id = 0 THEN
            -- Insert a new record in LeaveEntry
            INSERT INTO LEAVEENTRY (
                EmployeeCode,
                Month,
                Year,
                DicLeaveTypeId,
                LeaveDays,
                DicLeaveStatusId,
                LeaveEntryMainId,
                CreatedDate,
                CreatedBy
            )
            VALUES (
                r.employeecode,
                r.month,
                r.year,
                r.dicleavetypeid,
                r.leavedays,
                v_leave_status_id,
                v_main_id,
                SYSDATE,
                p_actionby
            );
        ELSE
            -- Update an existing record based on ID
            UPDATE LEAVEENTRY
            SET
                EmployeeCode = r.employeecode,
                DicLeaveTypeId = r.dicleavetypeid, --r.dicleavetypeid,
                LeaveDays = r.leavedays,
                -- LeaveEntryMainId = v_main_id,
                DicLeaveStatusId = v_leave_status_id,
                ModifiedDate = SYSDATE,
                ModifiedBy = p_actionby
            WHERE Id = r.id;
        END IF;
    END LOOP;

    -- Commit changes
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
    LOG_ERROR('usp_leaveentry_bulk_upsert', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
        ROLLBACK;
        RAISE;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_LEAVEENTRY_GETBYMAINID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_LEAVEENTRY_GETBYMAINID" (
  p_id IN NUMBER,
  p_pageno IN NUMBER DEFAULT NULL,
  p_pagesize IN NUMBER DEFAULT NULL,
  p_searchtext IN VARCHAR2 DEFAULT NULL,
  p_cursor OUT SYS_REFCURSOR
)
AS
v_start_row     NUMBER;
v_end_row       NUMBER;
v_params CLOB := 'Param_name:' || p_id;

BEGIN
     -- Calculate the start and end row for the current page
    v_start_row := (p_pageno - 1) * p_pagesize + 1;
    v_end_row := p_pageno * p_pagesize;

  OPEN p_cursor FOR
  WITH filtered_data AS 
      (
  SELECT
    LE.Id AS "Id", LE.EmployeeCode AS "EmployeeCode", E.FullName AS "EmployeeName", LE.DicLeaveTypeId AS "DicLeaveTypeId",
    LT.LeaveType AS "DicLeaveType", LE.LeaveDays AS "LeaveDays", LE.Month AS "Month", LE.Year AS "Year", LE.Comments AS "Comments",
    LE.DicLeaveStatusId AS "DicLeaveStatusId", LS.Value AS "DicLeaveStatus",LE.LeaveEntryMainId AS "LeaveEntryMainId",
    ROW_NUMBER() OVER (ORDER BY LE.ID) AS rownums
  FROM LeaveEntry LE
    INNER JOIN MasterEmployee E ON LE.EmployeeCode = E.EmployeeCode
    LEFT JOIN MasterLeave LT ON LE.DicLeaveTypeId = LT.Id
    LEFT JOIN Dictionary LS ON LE.DicLeaveStatusId = LS.NumId AND LS.Code = 'LEAVEENTRY_STATUS'

  WHERE LT.IsDeleted = 0 AND
  (p_searchtext IS NULL OR (
                          LOWER(LE.EmployeeCode) LIKE '%' || LOWER(p_searchtext) || '%' OR
                          LOWER(E.FullName) LIKE '%' || LOWER(p_searchtext) || '%' OR
                          LOWER(LE.Month) LIKE '%' || LOWER(p_searchtext) || '%' OR
                          LOWER(LE.Year) LIKE '%' || LOWER(p_searchtext) || '%' OR
                          LOWER(LT.LeaveType) LIKE '%' || LOWER(p_searchtext) || '%' OR
                          LOWER(LS.Value) LIKE '%' || LOWER(p_searchtext) || '%'
                    ))
  AND LE.LeaveEntryMainId = p_Id
  )

-- Step 2:applied pagination on filtered data
        SELECT (SELECT COUNT("Id") FROM filtered_data) AS "totalCount", 
            "Id",
            "EmployeeCode",
            "EmployeeName",
            "DicLeaveTypeId", 
            "DicLeaveType",
            "LeaveDays", 
            "Month", 
            "Year",
            "Comments",
            "DicLeaveStatusId", 
            "DicLeaveStatus",
            "LeaveEntryMainId"
            FROM 
            filtered_data  
       WHERE 
            rownums BETWEEN v_start_row AND v_end_row;
    EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_LeaveEntry_GetByMainId', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_LEAVEENTRYDETAIL_GETBYID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_LEAVEENTRYDETAIL_GETBYID" (
  p_Id IN NUMBER,
  p_cursor OUT SYS_REFCURSOR
)
AS
v_params CLOB := 'Param_name:' || p_id;
BEGIN
  OPEN p_cursor FOR
  SELECT
    LE.Id AS "Id", LE.EmployeeCode AS "EmployeeCode", E.FullName AS "EmployeeName", LE.DicLeaveTypeId AS "DicLeaveTypeId",
    LT.LeaveType AS "DicLeaveType", LE.LeaveDays AS "LeaveDays", LE.Month AS "Month", LE.Year AS "Year",
    LE.DicLeaveStatusId AS "DicLeaveStatusId", LS.Value AS "DicLeaveStatus",LE.LeaveEntryMainId AS "LeaveEntryMainId"
  FROM LeaveEntry LE
    INNER JOIN MasterEmployee E ON LE.EmployeeCode = E.EmployeeCode
    LEFT JOIN MasterLeave LT ON LE.DicLeaveTypeId = LT.Id
    LEFT JOIN Dictionary LS ON LE.DicLeaveStatusId = LS.NumId  AND LS.Code='LEAVEENTRY_STATUS'

  WHERE 
    LT.IsDeleted = 0 
    AND LE.Id = p_Id;

  EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_LeaveEntryDetail_GetById', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_LEAVEENTRYMAIN_GETALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_LEAVEENTRYMAIN_GETALL" (
    p_pageno IN NUMBER DEFAULT NULL,
    p_pagesize IN NUMBER DEFAULT NULL,
    p_officecode    IN VARCHAR2 DEFAULT NULL,  
    p_month IN VARCHAR2 DEFAULT NULL,  
    p_year IN VARCHAR2 DEFAULT NULL,
    p_searchtext IN VARCHAR2 DEFAULT NULL,
    p_cursor  OUT SYS_REFCURSOR
) AS
    v_start_row     NUMBER;
    v_end_row       NUMBER;
    v_value        VARCHAR2(50);
    v_local_officeCode VARCHAR2(50);
    v_params       CLOB := 'Param_name:' || p_pageno;

BEGIN
    -- Calculate the start and end row for the current page
    v_start_row := (p_pageno - 1) * p_pagesize + 1;
    v_end_row := p_pageno * p_pagesize;
    
    BEGIN
       SELECT dicofficetypeid INTO v_value 
      FROM masteroffice 
       WHERE officecode = p_officecode;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
           RAISE_APPLICATION_ERROR(-20003, 'Office not found.');
   END;
   
     IF v_value = '1' THEN
       v_local_officeCode := NULL;
    ELSE
      v_local_officeCode := p_officecode; -- Assign the original officeCode if not 1
    END IF;


    OPEN p_cursor FOR
      WITH filtered_data AS 
      (
        SELECT  LE.Id AS "Id", LE.OfficeCode AS "OfficeCode",
        O.OfficeName AS "OfficeName", LE.Month AS "Month", LE.Year AS "Year", 
                LE.DicStatusId AS "DicStatusId", LS.Value AS "DicStatusValue", 
                ROW_NUMBER() OVER (ORDER BY LE.ID) AS rownums
        FROM LeaveEntryMain LE
        INNER JOIN MasterOffice O ON LE.OfficeCode = O.OfficeCode 
        LEFT JOIN Dictionary LS ON LE.DicStatusId = LS.NumId AND LS.Code = 'LEAVEENTRY_STATUS'
        LEFT JOIN MASTEROFFICE MO1 ON MO1.Id = O.parentofficeid
        WHERE   (p_month IS NULL OR LE.Month = p_month) AND
                (p_year IS NULL  OR LE.Year = p_year) AND
                (p_searchtext IS NULL OR (
                          LOWER(LE.OfficeCode) LIKE '%' || LOWER(p_searchtext) || '%' OR
                          LOWER(O.OfficeName) LIKE '%' || LOWER(p_searchtext) || '%' OR
                          LOWER(LE.Month) LIKE '%' || LOWER(p_searchtext) || '%' OR
                          LOWER(LE.Year) LIKE '%' || LOWER(p_searchtext) || '%' OR
                          LOWER(LS.Value) LIKE '%' || LOWER(p_searchtext) || '%'
                    )) AND
                (v_local_officeCode IS NULL OR O.OfficeCode = v_local_officeCode)
                --AND (v_local_officeCode IS NULL OR O.parentofficeid = v_local_officeCode OR O.OfficeCode = v_local_officeCode)
            AND O.ISDELETED = 0 -- AND LS.ISDELETED = 0
            ORDER BY LE.Id DESC
      )
      
    -- Step 2:applied pagination on filtered data
        SELECT (SELECT COUNT("Id") FROM filtered_data) AS "totalCount", 
            "Id",
            "OfficeCode",
            "OfficeName",
            "Month", 
            "Year",
            "DicStatusId", 
            "DicStatusValue"
            FROM 
            filtered_data  
       WHERE 
            rownums BETWEEN v_start_row AND v_end_row;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_LeaveEntryMain_GetAll', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
END USP_LeaveEntryMain_GetAll;

/
--------------------------------------------------------
--  DDL for Procedure USP_LEAVEENTRYMAIN_GETBYID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_LEAVEENTRYMAIN_GETBYID" (
  p_Id IN NUMBER,
  p_cursor OUT SYS_REFCURSOR
)
AS
v_params CLOB := 'Param_name:' || p_id;

BEGIN
  OPEN p_cursor FOR
    SELECT
    LE.Id AS "Id",LE.OfficeCode AS "OfficeCode",O.OfficeName AS "OfficeName", LD.Value AS "OfficeTtype",
    LE.Month AS "Month",LE.Year AS "Year",LE.DicStatusId AS "DicStatusId", LS.Value AS "DicStatusValue"
    FROM LeaveEntryMain LE
    INNER JOIN MasterOffice O ON LE.OfficeCode = O.OfficeCode 
    -- LEFT JOIN MasterOfficeType OT ON O.OfficeTypeId=OT.Id
    LEFT JOIN Dictionary LD ON O.OFFICETYPEID = LD.NumId AND LD.CODE = 'OFFICE_TYPE' 
    LEFT JOIN Dictionary LS ON LE.DicStatusId = LS.NumId AND LS.CODE = 'LEAVEENTRY_STATUS' 
    WHERE  O.IsDeleted = 0 AND LE.Id = p_Id;

 EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_LeaveEntryMain_GetById', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_LEAVEENTRYMAIN_CHECKMAINISAPPROVED
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_LEAVEENTRYMAIN_CHECKMAINISAPPROVED" (
    p_officecode IN VARCHAR2,
    p_month IN VARCHAR2,
    p_year IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        Id AS "id",
        OfficeCode AS "officeCode",
        Month AS "month",
        Year AS "year",
        NVL(DicStatusId,0) AS "dicStatusId"
    FROM LeaveEntryMain 
    WHERE OfficeCode=p_officecode AND Month=p_month AND Year=p_year;

    EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_MASTERCITY_GetCityById', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, 'Somthing error');

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MANAGEEMPLOYEEROLES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MANAGEEMPLOYEEROLES" (
    p_employeeCode IN VARCHAR2,
    p_roleIds      IN VARCHAR2,
    p_CREATEDBY IN VARCHAR2,
    P_MODIFIEDBY IN VARCHAR2 Default NULL-- Comma-separated RoleIDs (e.g., '1,2,3')
)
AS
v_params CLOB := 'Param_employeecode:' || p_employeecode;
BEGIN
    -- Step 1: Update EXPIREDDATE for RoleIDs not in the provided list
    UPDATE MASTEREMPLOYEEROLE
    SET EXPIREDDATE = CURRENT_TIMESTAMP,
        MODIFIEDBY=P_MODIFIEDBY,
        MODIFIEDDATE=Current_TimeStamp
    WHERE EMPLOYEECODE = p_employeeCode
      AND ROLEID NOT IN (
          SELECT TO_NUMBER(REGEXP_SUBSTR(p_roleIds, '[^,]+', 1, LEVEL))
          FROM DUAL
          CONNECT BY LEVEL <= REGEXP_COUNT(p_roleIds, ',') + 1
      );

    -- Step 2: Insert new RoleIDs into the table (if not already present)
    INSERT INTO MASTEREMPLOYEEROLE (EMPLOYEECODE, ROLEID,CREATEDBY,CREATEDDATE)
    SELECT p_employeeCode, role_id,p_CREATEDBY, Current_TimeStamp
    FROM (
        SELECT TO_NUMBER(REGEXP_SUBSTR(p_roleIds, '[^,]+', 1, LEVEL)) AS role_id
        FROM DUAL
        CONNECT BY LEVEL <= REGEXP_COUNT(p_roleIds, ',') + 1
    )
    WHERE role_id NOT IN (
        SELECT ROLEID
        FROM MASTEREMPLOYEEROLE
        WHERE EMPLOYEECODE = p_employeeCode
      );
    
    COMMIT;  
    
  EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_ManageEmployeeRoles', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);    
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTER_MENU
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTER_MENU" ( 
   p_rolecode  IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) 
AS

v_params CLOB := 'p_rolecode:' || p_rolecode;
BEGIN
    OPEN p_cursor FOR
        SELECT
            id as "id",
            name AS "displayName",
            icon AS "icon",
            url AS "url",
            sortorder AS "sortby",
            0 AS "count"
        FROM
            mastermenu m
        WHERE
            m.ISACTIVE = 1 AND m.ISMENU = 1;

    EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_Master_Menu', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTER_WIDGETS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTER_WIDGETS" (
    p_rolecode  IN NUMBER,
     p_cursor OUT SYS_REFCURSOR
) 
AS
v_params CLOB := 'p_rolecode:' || p_rolecode;
BEGIN
    OPEN p_cursor FOR
        SELECT
            id as "id",
          name AS "displayName",
            icon AS "icon",
            url AS "url",
            sortorder AS "sortby",
            0 AS "count"
        FROM
            mastermenu m
        WHERE
            m.ISACTIVE = 1 AND m.ISMENU = 0;

            EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_Master_WIDGETS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);     
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERCITY_CREATEORUPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERCITY_CREATEORUPDATE" (
    p_id                   IN NUMBER,
    p_name                 IN VARCHAR2,
    p_masterstateid        IN NUMBER,
    p_mastercitycategoryid IN NUMBER,
    p_additionalhra        IN NUMBER DEFAULT 0,
    p_isactive             IN NUMBER DEFAULT 1,
    p_actionby             IN VARCHAR2 DEFAULT NULL
)
AS
    v_count NUMBER;
    v_params CLOB := 'p_id:' || p_id ;
BEGIN
    -- Check if the record exists
    SELECT COUNT(*) INTO v_count FROM MasterCity WHERE Id = p_id;

    IF v_count > 0 THEN
        -- Update the existing record
        UPDATE MasterCity
        SET Name = p_name,
            MasterStateId = p_masterstateid,
            MasterCityCategoryId = p_mastercitycategoryid,
            AdditionalHRA = p_additionalhra,
            IsActive = p_isactive,
            ModifiedBy = p_actionby,
            ModifiedDate = CURRENT_TIMESTAMP
        WHERE Id = p_id;
    ELSE
        -- Insert a new record
        INSERT INTO MasterCity (Name, MasterStateId, MasterCityCategoryId, AdditionalHRA, IsActive, CreatedBy, CreatedDate)
        VALUES (p_name, p_masterstateid, p_mastercitycategoryid, p_additionalhra, p_isactive, p_actionby, CURRENT_TIMESTAMP);
    END IF;

    -- Commit the transaction
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
         LOG_ERROR('USP_MasterCity_CreateOrUpdate', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
        RAISE;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERCITY_DELETE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERCITY_DELETE" (
    P_ID IN NUMBER,
      P_DELETEDBY Varchar2 Default NULL
)
AS
v_params CLOB := 'P_ID:' || P_ID;
BEGIN
    UPDATE MasterCity
    SET isDeleted = 1,
        DeletedDate = CURRENT_TIMESTAMP,
        DeletedBy=P_DELETEDBY
    WHERE Id = P_ID ;

   Commit;
    -- Check if a record was actually updated
    IF SQL%ROWCOUNT = 0 THEN
      Rollback;
    END IF;
   EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_MAsterCity_Delete', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params); 
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERCITY_GETALLCITIES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERCITY_GETALLCITIES" (
    p_pageNo IN NUMBER DEFAULT NULL,
    p_pageSize IN NUMBER DEFAULT NULL,
    p_searchText IN NVARCHAR2 DEFAULT NULL,
   /*  p_page_sortColumn IN VARCHAR2 DEFAULT NULL,
    p_page_sortDirection IN NUMBER DEFAULT NULL,*/
    p_stateid IN NUMBER DEFAULT   NULL,
    p_citycategoryid IN NUMBER DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
) AS
    v_offset NUMBER;
    v_limit NUMBER;
    v_sort_direction VARCHAR2(4);
    v_sort_column VARCHAR2(50);
    v_params CLOB := 'p_pageNo:' || p_pageNo;
BEGIN
    -- Calculate offset and limit for pagination
    IF p_pageNo IS NOT NULL AND p_pageSize IS NOT NULL THEN
        v_offset := (p_pageNo - 1) * p_pageSize;
        v_limit := p_pageSize;
    ELSE
        v_offset := NULL;
        v_limit := NULL;
    END IF;

    -- Determine sort direction
/*    IF p_page_sortDirection = 1 THEN
        v_sort_direction := 'ASC';
    ELSE
        v_sort_direction := 'DESC';
    END IF;*/

    -- Set sort column with default fallback
  /*  v_sort_column := NVL(p_page_sortColumn, 'cm.Id');*/

    -- Open the cursor with filtering, sorting, and pagination logic
    OPEN p_cursor FOR
        SELECT 
            cm.Id AS "id",
            cm.Name AS "name",
            ms.StateName AS "stateName",
            ms.Id AS "masterStateId",
            mcc.Id AS "masterCityCategoryId",
            mcc.Name AS "masterCityCategoryName",
            cm.AdditionalHRA AS "additionalHRA",
            mcc.HRA AS "hra",
            mcc.MinHRA AS "minHRA"
        FROM MasterCity cm
        LEFT JOIN MasterCityCategory mcc ON cm.MasterCityCategoryId = mcc.Id
        LEFT JOIN MasterState ms ON cm.MasterStateId = ms.Id
        WHERE cm.ISDELETED = 0
        AND (p_stateid IS NULL OR cm.MasterStateId = p_stateid)
        AND (p_citycategoryid IS NULL OR cm.MasterCityCategoryId = p_citycategoryid)
        AND (p_searchText IS NULL OR 
               UPPER(cm.Name) LIKE '%' || UPPER(p_searchText) || '%' OR
               UPPER(ms.StateName) LIKE '%' || UPPER(p_searchText) || '%' OR
               UPPER(mcc.Name) LIKE '%' || UPPER(p_searchText) || '%')
    ORDER BY CASE v_sort_column
            WHEN 'Name' THEN cm.Name 
            WHEN 'MasterCityCategoryName' THEN mcc.Name
            ELSE cm.Name 
            END || ' ' || v_sort_direction
    OFFSET v_offset ROWS 
    FETCH NEXT v_limit ROWS ONLY;

 EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_MASTERCITY_GetAllCities', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);   
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERCITY_GETCITYBYID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERCITY_GETCITYBYID" (
    p_Id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
v_params CLOB := 'p_Id:' || p_Id;
BEGIN
    OPEN p_cursor FOR
    SELECT 
        cm.Id AS "id",
        cm.Name AS "name",
        ms.StateName AS "stateName",
        ms.Id AS "masterStateId",
        mcc.Id AS "masterCityCategoryId",
        mcc.Name AS "masterCityCategoryName",
        cm.AdditionalHRA AS "additionalHRA",
        mcc.HRA AS "hra",
        mcc.MinHRA AS "minHRA"
    FROM MasterCity cm
    LEFT  JOIN MasterState ms ON cm.MasterStateId = ms.Id
    LEFT  JOIN MasterCityCategory mcc ON cm.MasterCityCategoryId = mcc.Id
    WHERE cm.Id = p_Id AND cm.ISDELETED = 0;

    EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_MASTERCITY_GetCityById', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERCITYCATEGORY_CRUD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERCITYCATEGORY_CRUD" (
    p_operation IN VARCHAR2,
    p_id IN NUMBER DEFAULT NULL,
    p_name IN VARCHAR2 DEFAULT NULL,
    p_hra IN NUMBER DEFAULT NULL,
    p_minhra IN NUMBER DEFAULT NULL,
    p_isactive IN NUMBER DEFAULT NULL,
    p_createdby IN VARCHAR2 DEFAULT NULL,
    p_modifiedby IN VARCHAR2 DEFAULT NULL,
    p_deletedby IN VARCHAR2 DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
)
AS
v_params CLOB := 'p_operation:' || p_operation;
BEGIN
    IF p_operation = 'INSERT' THEN
        INSERT INTO MasterCityCategory (NAME, HRA, MINHRA, ISACTIVE, CREATEDBY, CREATEDDATE, IsDeleted)
        VALUES (p_name, p_hra, p_minhra, p_isactive, p_createdby, SYSDATE, 0);
        COMMIT;

    ELSIF p_operation = 'UPDATE' THEN
        UPDATE MasterCityCategory
        SET NAME = p_name,
            HRA = p_hra,
            MINHRA = p_minhra,
            ISACTIVE = p_isactive,
            MODIFIEDBY = p_modifiedby,
            MODIFIEDDATE = SYSDATE
        WHERE ID = p_id AND IsDeleted = 0;
        COMMIT;

    ELSIF p_operation = 'DELETE' THEN
        UPDATE MasterCityCategory
        SET IsDeleted = 1,
            DeletedBy = p_deletedby,
            DeletedDate = SYSDATE
        WHERE ID = p_id;
        COMMIT;

    ELSIF p_operation = 'GET_ALL' THEN
        OPEN p_cursor FOR
        SELECT * FROM MasterCityCategory WHERE IsDeleted = 0;

    ELSIF p_operation = 'GET_BY_ID' THEN
        OPEN p_cursor FOR
        SELECT * FROM MasterCityCategory WHERE ID = p_id AND IsDeleted = 0;

    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Invalid operation specified');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('usp_MasterCityCategory_CRUD', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERCITYCATEGORY_GETALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERCITYCATEGORY_GETALL" (
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT ID, NAME, HRA, MINHRA, ISACTIVE, CREATEDBY, CREATEDDATE, MODIFIEDBY, MODIFIEDDATE
    FROM MasterCityCategory
    WHERE IsDeleted = 0;

EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_MASTERCITYCATEGORY_GETALL', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, 'no_parameter');
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERDESIGNATION_CREATEUPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "USP_MASTERDESIGNATION_CREATEUPDATE" (
    p_id           IN INT,
    p_name     IN VARCHAR2,
    p_isactive     IN NUMBER,
    p_CreatedBy    IN VARCHAR2 DEFAULT NULL,
    p_CreatedDate  IN DATE DEFAULT NULL,
    p_ModifiedBy   IN VARCHAR2 DEFAULT NULL,
    p_ModifiedDate IN DATE DEFAULT NULL
) AS
v_params CLOB := 'p_id:' || p_id;
BEGIN
    IF p_id > 0 THEN
        -- Update operation
        UPDATE MasterDesignation
        SET
            Name = p_name,
            IsActive = p_isactive,
            ModifiedBy = NVL(p_ModifiedBy, ''), -- Default to 'Unknown' if ModifiedBy is NULL
            ModifiedDate = NVL(p_ModifiedDate, SYSDATE) -- Use provided ModifiedDate or current timestamp
        WHERE Id = p_Id ;

        IF SQL%ROWCOUNT = 0 THEN
            -- If no rows are affected, it means the record doesn't exist
            RAISE_APPLICATION_ERROR(-20001, 'Record not found for update');
        END IF;

    ELSE
        -- Insert operation (for p_Id = 0 or NULL)
        INSERT INTO MasterDesignation (
            Name,
            IsActive,
            CreatedBy,
            CreatedDate
        )
        VALUES (
            p_name,
            p_isactive,
            NVL(p_CreatedBy,''), -- Assuming 'Tejasvi' is the user performing the insert
            SYSDATE   -- Automatically insert current timestamp for CreatedDate
        );
    END IF;

    COMMIT;  -- Commit the transaction

    EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('usp_masterdesignation_createupdate', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END usp_masterdesignation_createupdate;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERDESIGNATION_TEST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERDESIGNATION_TEST" (
    p_id           IN INT,
    p_name         IN VARCHAR2,
    p_isactive     IN NUMBER,
    p_CreatedBy    IN VARCHAR2 DEFAULT NULL,
    p_CreatedDate  IN DATE DEFAULT NULL,
    p_ModifiedBy   IN VARCHAR2 DEFAULT NULL,
    p_ModifiedDate IN DATE DEFAULT NULL,
    O_Code         OUT NUMBER,
    O_Message      OUT VARCHAR2
) AS
    ID_COUNT NUMBER;
    NAME_COUNT    NUMBER;
    P_COUNT        NUMBER;
    v_params       CLOB := 'P_name:' || p_name;

BEGIN

SELECT COUNT(*) INTO ID_COUNT FROM MASTERDESIGNATION WHERE ID =P_ID;

    IF ID_COUNT =1 THEN   ---> Valid ID and data available

        UPDATE MasterDesignation
        SET
            Name = p_name,
            IsActive = p_isactive,
            ModifiedBy = NVL(p_ModifiedBy, ''), 
            ModifiedDate = NVL(p_ModifiedDate, SYSDATE) 
        WHERE Id = p_Id ;

		  O_Code := 101;
          O_Message := 'DATA UPDATED SUCCESSFULLT';

    ELSE        -- No data available for the ID provided
        O_Code := 102;
        O_Message := 'Invalid ID. Please Check ';

    END IF ;


		SELECT COUNT(*) INTO NAME_COUNT FROM MASTERDESIGNATION WHERE NAME = P_NAME;

        IF NAME_COUNT = 0 THEN

        INSERT INTO MasterDesignation (
            Name,
            IsActive,
            CreatedBy,
            CreatedDate
        )
        VALUES (
            p_name,
            p_isactive,
            NVL(p_CreatedBy,''), 
            SYSDATE   
        );

		O_Code := 100;
        O_Message := 'DATA INSERTED SUCESSFULLY';



		END IF;


    COMMIT;  
EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('usp_masterdesignation_test', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END usp_masterdesignation_test;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERDYNAMIC_ALLBYID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "USP_MASTERDYNAMIC_ALLBYID" (
    p_table_name IN VARCHAR2,  -- Table name as input parameter
    p_cursor     OUT SYS_REFCURSOR  -- Output cursor
) AS
    v_sql VARCHAR2(4000);  -- Variable to hold the dynamic SQL query
    v_params CLOB := 'p_table_name:' || p_table_name;
BEGIN
    -- Build the dynamic SQL statement with the IsActive = 1 condition
    v_sql := 'SELECT * FROM ' || p_table_name || ' WHERE  IsDeleted = 0 ';

    -- Open the cursor using dynamic SQL
    OPEN p_cursor FOR v_sql;

EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('usp_masterdynamic_allbyid', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END usp_masterdynamic_allbyid;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERDYNAMIC_DELETE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERDYNAMIC_DELETE" (
    P_ID IN NUMBER,
    P_ActionBy IN VARCHAR2 DEFAULT NULL,
    P_TABLENAME IN VARCHAR2 DEFAULT NULL
)
AS
    -- Declare the dynamic SQL query as a string
    v_sql VARCHAR2(4000);
    v_params CLOB := 'P_ID:' || P_ID;
BEGIN
    -- Construct the dynamic SQL statement for updating the table
    v_sql := 'UPDATE ' || P_TABLENAME || 
             ' SET IsActive=0, ISDELETED = 1, DeletedBy = :P_ActionBy, DELETEDDATE=SYSDATE WHERE ID = :P_ID
             AND ISDELETED=0';

    -- Execute the dynamic SQL statement
    EXECUTE IMMEDIATE v_sql USING P_ActionBy, P_ID;

    -- Commit the transaction
    COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_MasterDynamic_Delete', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END USP_MasterDynamic_Delete;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERDYNAMIC_GETALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "USP_MASTERDYNAMIC_GETALL" (
    p_page_no            IN INT DEFAULT NULL,      
    p_page_size          IN INT DEFAULT NULL,         
    p_page_sortColumn    IN VARCHAR2 DEFAULT NULL,    
    p_page_sortDirection IN NUMBER DEFAULT NULL,          
    p_table_name         IN VARCHAR2,                       
    p_page_searchText    IN VARCHAR2 DEFAULT NULL,         
    p_cursor             OUT SYS_REFCURSOR       
)
AS
    v_start_row   INT;
    v_end_row     INT;
    v_sql         VARCHAR2(4000);
    v_order_by    VARCHAR2(1000);
    v_search_clause VARCHAR2(1000);
    v_params       CLOB := 'Param_name:' || p_page_no;
BEGIN

    v_start_row := (p_page_no - 1) * p_page_size + 1;
    v_end_row := p_page_no * p_page_size;

    IF p_page_sortColumn IS NOT NULL THEN
        IF p_page_sortDirection = 1 THEN
            v_order_by := 'ORDER BY ' || p_page_sortColumn || ' ASC';
        ELSE
            v_order_by := 'ORDER BY ' || p_page_sortColumn || ' DESC';
        END IF;
    ELSE
        v_order_by := 'ORDER BY Id';  
    END IF;

    IF p_page_searchText IS NOT NULL AND LENGTH(p_page_searchText) > 0 THEN
        v_search_clause := 'WHERE (' || 
                           'LOWER(a.column1) LIKE LOWER(''' || '%' || p_page_searchText || '%'' ) OR ' ||
                           'LOWER(a.column2) LIKE LOWER(''' || '%' || p_page_searchText || '%'' ) OR ' ||
                           'LOWER(a.column3) LIKE LOWER(''' || '%' || p_page_searchText || '%'' )' ||  -- Add other columns as needed
                           ') AND a.ISDELETED = 0'; 
    ELSE
        v_search_clause := 'WHERE a.ISDELETED = 0';  
    END IF;

    v_sql := 'SELECT * FROM ( ' || 
             'SELECT a.*, ROW_NUMBER() OVER (' || v_order_by || ') AS rownums ' ||
             'FROM ' || p_table_name || ' a ' || v_search_clause || ') r ' ||
             'WHERE r.rownums BETWEEN :start_row AND :end_row';

    OPEN p_cursor FOR v_sql USING v_start_row, v_end_row;


EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_Masterdynamic_getall', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END USP_Masterdynamic_getall;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEREMPLOYEE_CREATEUPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEREMPLOYEE_CREATEUPDATE" (
    -- Employee Master Parameters
    p_id                    IN NUMBER,
	
    p_employeecode          IN VARCHAR2,
    p_firstname             IN VARCHAR2,
    p_middlename            IN VARCHAR2 DEFAULT NULL,
    p_lastname              IN VARCHAR2 DEFAULT NULL,
	p_gender                IN NUMBER DEFAULT NULL,
	
    p_dateofbirth           IN DATE,
    p_email                 IN NVARCHAR2 ,
    p_mobile                IN NVARCHAR2 DEFAULT NULL,
    p_panno                 IN NVARCHAR2,
	p_schemetype            IN NUMBER DEFAULT NULL,
	
    p_officeid              IN NUMBER,
    p_dateofjoining         IN DATE DEFAULT NULL,
    p_dateofjoiningkvs      IN DATE DEFAULT NULL,
    p_designationid         IN NUMBER,
	
    p_lastincrementdate     IN DATE DEFAULT NULL,
    p_nextincrementdate     IN DATE DEFAULT NULL,
    p_levelid               IN NUMBER,
    p_basicpay              IN NUMBER,
	p_isallotmentquarter    IN NUMBER DEFAULT NULL,
	
    p_typeofquarter         IN NUMBER DEFAULT NULL,
    p_isadditionhra         IN NUMBER DEFAULT NULL,
    p_additionalhracity     IN NUMBER DEFAULT NULL,
    p_ishandicap            IN NUMBER DEFAULT NULL,
	p_dateofcertificate     IN DATE DEFAULT NULL,
	
    p_entitlefordoubleta    IN NUMBER DEFAULT NULL,
    p_password              IN VARCHAR2 DEFAULT NULL,
  
    p_cpfownshare           IN DECIMAL Default NULL, 
    p_gpfownshare           IN DECIMAL Default NULL, 
    p_slabtype              IN NUMBER  Default NULL ,
    p_createdby             IN VARCHAR2 DEFAULT NULL,
    p_modifiedby            IN VARCHAR2 DEFAULT NULL,
   
    -- Address Master Parameters
    p_addressline1          IN VARCHAR2 DEFAULT NULL,
    p_addressline2          IN VARCHAR2 DEFAULT NULL,
    p_city                  IN VARCHAR2 DEFAULT NULL,
    p_state                 IN NUMBER DEFAULT NULL,
    p_pin                   IN VARCHAR2 DEFAULT NULL,
    -- Bank Master Parameters
    p_bankname              IN VARCHAR2 DEFAULT NULL,
    p_accountnumber         IN NVARCHAR2 DEFAULT NULL,
    p_ifsccode              IN NVARCHAR2 DEFAULT NULL,
    p_uannumber             IN NVARCHAR2 DEFAULT NULL
)
AS
    V_EMPLOYEE_ID NUMBER;
    v_params CLOB := 'p_id:' || p_id;
BEGIN
    BEGIN
        SELECT ID 
        INTO V_EMPLOYEE_ID
        FROM MASTEREMPLOYEE 
        WHERE ID = P_ID;

        -- If employee exists, update
        UPDATE MASTEREMPLOYEE
        SET EMPLOYEECODE = P_EMPLOYEECODE,
            FIRSTNAME = P_FIRSTNAME,
            MIDDLENAME = P_MIDDLENAME,
            LASTNAME = P_LASTNAME,
            GENDER = P_GENDER,
            DATEOFBIRTH = P_DATEOFBIRTH,
            EMAIL = P_EMAIL,
            MOBILE = P_MOBILE,
            PANNO = P_PANNO,
            SCHEMETYPE = P_SCHEMETYPE,
            OFFICEID = P_OFFICEID,
            DATEOFJOINING = P_DATEOFJOINING,
            DATEOFJOININGKVS = P_DATEOFJOININGKVS,
            DESIGNATIONID = P_DESIGNATIONID,
            LASTINCREMENTDATE = P_LASTINCREMENTDATE,
            NEXTCREMENTDATE = P_NEXTINCREMENTDATE,
            LEVELID = P_LEVELID,
            BASICPAY = P_BASICPAY,
            ISALLOTMENTQUARTER = P_ISALLOTMENTQUARTER,
            TYPEOFQUARTER = P_TYPEOFQUARTER,
            ISADDITIONHRA = P_ISADDITIONHRA,
            ADDITIONALHRACITY = P_ADDITIONALHRACITY,
            ISHANDICAP = P_ISHANDICAP,
            DATEOFCERTIFICATE = P_DATEOFCERTIFICATE,
            ENTITLEFORDOUBLETA = P_ENTITLEFORDOUBLETA,
            PASSWORD= p_password,
            CPFOwnShare=p_cpfownshare,
            GPFOwnShare=p_gpfownshare,
            SlabType=p_slabtype,
            MODIFIEDDATE = CURRENT_TIMESTAMP,
            MODIFIEDBY = P_MODIFIEDBY
        WHERE ID = V_EMPLOYEE_ID;

        UPDATE MASTERBANK
        SET BANKNAME = P_BANKNAME,
            ACCOUNTNUMBER = P_ACCOUNTNUMBER,
            IFSCCODE = P_IFSCCODE,
            UANNUMBER = P_UANNUMBER,
            MODIFIEDDATE = CURRENT_TIMESTAMP,
            MODIFIEDBY = P_MODIFIEDBY
        WHERE EMPLOYEECODE = P_EMPLOYEECODE;

        UPDATE MASTERADDRESS
        SET ADDRESS1 = P_ADDRESSLINE1,
            ADDRESS2 = P_ADDRESSLINE2,
            CITY = P_CITY,
            STATEID = P_STATE,
            PIN = P_PIN,
            MODIFIEDDATE = CURRENT_TIMESTAMP,
            MODIFIEDBY = P_MODIFIEDBY
        WHERE TABLEKEY = V_EMPLOYEE_ID AND TABLENAME = 'MASTEREMPLOYEE';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- If employee does not exist, insert
            INSERT INTO MASTEREMPLOYEE (
                EMPLOYEECODE, FIRSTNAME, MIDDLENAME, LASTNAME, GENDER, 
                DATEOFBIRTH, EMAIL, MOBILE, PANNO, SCHEMETYPE, OFFICEID, 
                DATEOFJOINING, DATEOFJOININGKVS, DESIGNATIONID, LASTINCREMENTDATE, 
                NEXTCREMENTDATE, LEVELID, BASICPAY, ISALLOTMENTQUARTER, TYPEOFQUARTER, 
                ISADDITIONHRA, ADDITIONALHRACITY, ISHANDICAP, DATEOFCERTIFICATE, ENTITLEFORDOUBLETA, PASSWORD,CPFOwnShare,GPFOwnShare,SlabType,
                  CREATEDDATE, 
                CREATEDBY
            ) VALUES (
                P_EMPLOYEECODE, P_FIRSTNAME, P_MIDDLENAME, P_LASTNAME, P_GENDER, 
                P_DATEOFBIRTH, P_EMAIL, P_MOBILE, P_PANNO, P_SCHEMETYPE, P_OFFICEID, 
                P_DATEOFJOINING, P_DATEOFJOININGKVS, P_DESIGNATIONID, P_LASTINCREMENTDATE, 
                P_NEXTINCREMENTDATE, P_LEVELID, P_BASICPAY, P_ISALLOTMENTQUARTER, P_TYPEOFQUARTER, 
                P_ISADDITIONHRA, P_ADDITIONALHRACITY, P_ISHANDICAP, P_DATEOFCERTIFICATE, P_ENTITLEFORDOUBLETA, p_password,p_cpfownshare,p_gpfownshare,p_slabtype,
                  CURRENT_TIMESTAMP, 
                P_CREATEDBY
            ) RETURNING ID INTO V_EMPLOYEE_ID;

            INSERT INTO MASTERBANK (
                EMPLOYEECODE, BANKNAME, ACCOUNTNUMBER, IFSCCODE,  
                 UANNUMBER, CREATEDDATE, CREATEDBY
            ) VALUES (
                P_EMPLOYEECODE, P_BANKNAME, P_ACCOUNTNUMBER, P_IFSCCODE, 
                P_UANNUMBER, CURRENT_TIMESTAMP, P_CREATEDBY
            );

            INSERT INTO MASTERADDRESS (
                TABLEKEY, TABLENAME, ADDRESS1, ADDRESS2, CITY, STATEID, PIN, CREATEDDATE, CREATEDBY
            ) VALUES (
                V_EMPLOYEE_ID, 'MASTEREMPLOYEE', P_ADDRESSLINE1, P_ADDRESSLINE2, P_CITY, P_STATE, P_PIN, CURRENT_TIMESTAMP, P_CREATEDBY
            );
    END;

    COMMIT;

    EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_MasterEmployee_CreateUpdate', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEREMPLOYEE_GETALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEREMPLOYEE_GETALL" (
     p_pageno            IN INT DEFAULT NULL,           
     p_pagesize          IN INT DEFAULT NULL,          
     p_officecode         IN VARCHAR2 DEFAULT NULL,  
     p_employeecode       IN VARCHAR2 DEFAULT NULL,  
     p_loginemployeecode  IN VARCHAR2 DEFAULT NULL  , 
     p_searchtext         IN VARCHAR2 DEFAULT NULL,
     p_cursor             OUT SYS_REFCURSOR        
     --p_totalrecords       OUT INT                
)
AS
    v_start_row     NUMBER;
    v_end_row       NUMBER;
     v_officetype      NUMBER;
     V_OfficeID     Number;
BEGIN
    -- Calculate the start and end row for the current page
    v_start_row := (p_pageno - 1) * p_pagesize + 1;
    v_end_row := p_pageno * p_pagesize;
    

    SELECT OfficeID into V_OfficeID FROM MasterEMPLoyee WHERE EmployeeCode = NVL(p_loginemployeecode,0);

    SELECT 
         DICOFFICETYPEID INTO v_officetype 
    FROM MasterOffice 
    WHERE id = V_OfficeID;
    
    -- If the Office Type is HO , pass NULL to get all the employee data
    V_OfficeID := Case when v_officetype = 1 Then null ELSE V_OfficeID End;
    
    -- Step 1: Create a temporary query with filters and apply pagination using ROW_NUMBER()
    OPEN p_cursor FOR

    WITH filtered_data AS (
            SELECT
                ME.id AS "employeeId",
                ME.officeid AS "officeId",
                ME.employeecode AS "employeeCode",
                ME.firstname AS "firstName",
                ME.middlename AS "middleName",
                ME.lastname AS "lastName",
                MD.name AS "designationName",
                ME.designationid AS "designationId",
                ME.gender AS "gender",
                ME.dateofbirth AS "dateOfBirth",
                ME.levelid AS "levelId",
                ME.basicpay AS "basicPay",
                ME.panno AS "panNo",
                ME.password AS "password",
                ME.fullname AS "fullName",
                ME.email AS "email",
                ME.mobile AS "mobile",
                ME.dateofjoining AS "dateOfJoining",
                ME.dateofjoiningkvs AS "dateOfJoiningKVS",
                ME.currentdesignationdate AS "currentDesignationDate",
                ME.ishandicap AS "isHandicap",
                ME.isallotmentquarter AS "isAllotmentQuarter",
                ME.typeofquarter AS "typeOfQuarter",
                ME.isactive AS "isActive",
                ME.lastincrementdate AS "lastIncrementDate",
                ME.nextcrementdate AS "nextIncrementDate",
                ME.roleid AS "roleId",
                ME.isadditionhra AS "isAdditionHRA",
                ME.additionalhracity AS "additionalHRACity",
                ME.schemetype AS "schemeType",
                ME.entitlefordoubleta AS "entitleForDoubleTA",
                ME.CPFOwnShare As "cpfOwnShare",
                ME.GPFOwnShare AS "gpfOwnShare",
                ME.SlabType AS "slabType",
                MO.officeCode as "officeCode",
                MO.OFFICENAME as "officeName",
                ME.doubleta AS "doubleTA",
                MB.bankname AS "bankName",
                MA.address1 AS "addressLine1",
                MA.address2 AS "addressLine2",
                MA.city AS "cityName",
                MS.statename AS "state",
                MA.pin AS "pin",
                MB.accountnumber AS "accountNumber",
                MB.ifsccode AS "ifscCode",
                MB.uannumber AS "uanNumber", -- Make sure this column exists in the database
                (SELECT LISTAGG(r.ROLENAME, ', ') WITHIN GROUP (ORDER BY r.ROLENAME)
                    FROM MasterRole r
                    JOIN MASTEREMPLOYEEROLE er ON r.id = er.roleid
                    WHERE er.EMPLOYEECODE = ME.employeecode and er.EXPIREDDATE is NULL
                ) AS "roles",
                ROW_NUMBER() OVER (ORDER BY ME.ID) AS rownums
            FROM
                masteremployee ME
                LEFT JOIN masterbank MB ON ME.employeecode = MB.employeecode
               
                LEFT JOIN masteraddress MA ON (ME.id = MA.tablekey and mA.TABLEnAME = 'MASTEREMPLOYEE' )
             --   LEFT JOIN mastercity MC ON MA.cityid = MC.id
                LEFT JOIN masterstate MS ON MA.stateid = MS.id
               -- INNER JOIN mastercity f ON f.id = MB.bankcityid
                LEFT JOIN masterdesignation MD ON MD.id = ME.designationid
                LEFT JOIN masteroffice MO on MO.id=ME.officeId
            WHERE ME.isdeleted = 0    and  MD.IsDeleted=0 and MO.IsDeleted=0 
                 AND (p_searchtext IS NULL OR LOWER( ME.fullname) LIKE '%' || LOWER(p_searchtext) || '%' OR LOWER( ME.fullname) LIKE '%' || LOWER(p_searchtext) || '%')
                AND (LOWER(ME.officeId) LIKE LOWER(NVL(NULL, ME.officeId)) OR NULL IS NULL)
                AND (LOWER(ME.employeeCode) LIKE LOWER(NVL(NULL, ME.employeeCode)) OR NULL IS NULL)
                
                AND (LOWER(ME.employeeCode) LIKE LOWER(NVL(NULL, ME.employeeCode)) OR NULL IS NULL)
                 And (MO.id = nvl(V_OfficeID,MO.id) or MO.parentofficeid = nvl(V_OfficeID,MO.parentofficeid))
            )
            
               SELECT 
       (SELECT COUNT(1) FROM filtered_data) AS "totalCount", -- Total number of records (total count from CTE)
       filtered_data.*
   FROM filtered_data
   WHERE filtered_data.rownums BETWEEN ((p_pageno - 1) * p_pagesize + 1) AND (p_pageno * p_pagesize) -- Pagination
   ORDER BY filtered_data.rownums;
         /*   SELECT 
                (SELECT COUNT(*) FROM filtered_data) AS "totalCount", 
                "employeeId",
                "officeId",
                "employeeCode", 
                "firstName",
                "middleName",
                "lastName", 
                "designationId",
                "designationName",
                "gender", 
                "dateOfBirth",
                "levelId",
                "basicPay",
                "panNo",
                "password",
                "fullName",
                "email", 
                "mobile", 
                "dateOfJoining",
                "dateOfJoiningKVS", 
                "currentDesignationDate",
                "isHandicap",
                "isAllotmentQuarter",
                "typeOfQuarter", 
                "isActive", 
                "lastIncrementDate", 
                "nextIncrementDate",
                "roleId", 
                "isAdditionHRA",
                "additionalHRACity", 
                "schemeType", 
                "entitleForDoubleTA",
                "officeCode",
                "officeName",
                "doubleTA",
                "bankName",
                "addressLine1",
                "addressLine2",
                "cityName",
                "state",
                "pin",
                "accountNumber",
                "ifscCode",
                "roles",
                "uanNumber"
            FROM 
                filtered_data
            WHERE 
                    rownums BETWEEN v_start_row AND v_end_row;*/
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEREMPLOYEE_GETALLEMPLOYEE_BYOFFFICECODE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEREMPLOYEE_GETALLEMPLOYEE_BYOFFFICECODE" (
  p_officecode IN VARCHAR2 DEFAULT NULL,
  p_cursor OUT SYS_REFCURSOR
)
AS
v_params CLOB := 'p_officecode:' || p_officecode;
BEGIN
    OPEN p_cursor FOR
        SELECT  E.EmployeeCode AS "EmployeeCode",
                E.EmployeeCode || ' - ' || E.FullName AS "EmployeeName"
        FROM MasterEmployee E
        INNER JOIN MasterOffice O ON E.OfficeId = O.Id
        WHERE E.IsDeleted = 0 AND O.IsDeleted = 0 
               AND O.OfficeCode = p_officecode;
    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
        -- Log error
        LOG_ERROR('USP_MasterEmployee_GetAllEmployee_ByOffficeCode', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEREMPLOYEE_GETBYID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEREMPLOYEE_GETBYID" (
  p_Id IN NUMBER,
  p_cursor OUT SYS_REFCURSOR
)
AS
v_params CLOB := 'p_Id:' || p_Id;
BEGIN
  OPEN p_cursor FOR
  SELECT
    ME.id AS "id",
    ME.employeecode AS "employeeCode",
    ME.firstname AS "firstName",
    ME.middlename AS "middleName",
    ME.lastname AS "lastName",
    ME.gender as "gender",
    ME.dateofbirth AS "dateOfBirth",
    ME.email AS "email",
    ME.mobile AS "mobile",
    ME.panno AS "panNo",
    ME.schemetype AS "schemeType",
    ME.officeid AS "officeId",
    ME.dateofjoining AS "dateOfJoining",
    ME.DATEOFJOININGKVS AS "dateOfJoiningKvs",
    ME.DESIGNATIONID AS "designationId",
    ME.roleid AS "roleId",
    ME.lastincrementdate AS "lastIncrementDate",
    ME.nextcrementdate AS "nextIncrementDate",
    ME.levelid AS "levelId",
    ME.basicpay AS "basicPay",
    ME.isallotmentquarter AS "isAllotmentQuarter",
    ME.typeofquarter AS "typeOfQuarter",
    ME.isadditionhra AS "isAdditionHra",
    ME.additionalhracity AS "additionalHraCity",
    ME.ishandicap AS "isHandicap",
    ME.dateofcertificate AS "dateOfCertificate",
    ME.entitlefordoubleta AS "entitledForDoubleTA",
    ME.CPFOwnShare As "cpfownshare",
    ME.GPFOwnShare AS "gpfownshare",
    ME.SlabType AS "slabtype",
    -- Address object

      MA.ADDRESS1 as "addressLine1",
      MA.ADDRESS2 as "addressLine2",
      MA.PIN  as "pin",
      MA.city as "city",
      MS.ID as "stateId",


    -- Bank object

       MB.BANKNAME as "bankName",
       MB.ACCOUNTNUMBER as "accountNumber",
       MB.IFSCCODE as "ifscCode",
      MB.UANNUMBER as "uanNumber",
      (
          Select LISTAGG(r.RoleId,',') WITHIN GROUP (ORDER BY r.RoleId) as "roles" 

            From MASTEREMPLOYEEROLE r where r.EMPLOYEECODE  = ME.employeecode  and r.EXPIREDDATE is NULL 

      ) as "roles"


  FROM
    masteremployee ME
    LEFT JOIN MASTERBANK MB ON ME.EMPLOYEECODE = MB.EMPLOYEECODE
    LEFT JOIN MASTERADDRESS MA ON ME.ID = MA.TABLEKEY
    LEFT JOIN MASTERCITY MC ON MA.CITYID = MC.ID
    LEFT JOIN MASTERSTATE MS ON MA.STATEID = MS.ID
    LEFT JOIN MASTERCITY MCC ON MCC.ID = MB.BANKCITYID
    LEFT JOIN MASTERDESIGNATION MD ON MD.ID = ME.DESIGNATIONID

  WHERE 
    ME.IsDeleted = 0 and MA.TABLENAME='MASTEREMPLOYEE'
    AND ME.ID = p_Id;

   EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
        -- Log error
        LOG_ERROR('USP_MasterEmployee_GetByID', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEREMPLOYEE_GETROLE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEREMPLOYEE_GETROLE" (
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT * FROM VM_MasterEmployeeRole;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEREMPLOYEE_GETROLEALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEREMPLOYEE_GETROLEALL" (
    p_EmployeeCode IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT v.*, v.RoleName "name"
    FROM VM_MasterEmployeeRoleAll v
    WHERE v.EmployeeCode = p_EmployeeCode;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEREMPLOYEEROLE_INSERTUPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEREMPLOYEEROLE_INSERTUPDATE" (
    p_EMPLOYEECODE IN VARCHAR2,
    p_ROLEID IN NUMBER,
    p_CREATEDBY IN VARCHAR2,
    P_MODIFIEDBY IN VARCHAR2 Default NULL
    
) AS
v_params CLOB := 'p_EMPLOYEECODE:' || p_EMPLOYEECODE;
BEGIN
    INSERT INTO MASTEREMPLOYEEROLE (
        EMPLOYEECODE,
        ROLEID,
        CREATEDBY,
        CREATEDDATE
    ) VALUES (
        p_EMPLOYEECODE,
        p_ROLEID,
        p_CREATEDBY,
        CURRENT_TIMESTAMP
    );

    -- Optionally, commit the transaction if the procedure is called outside of an autonomous block
    -- Uncomment the next line if needed
    -- COMMIT;
EXCEPTION
 WHEN OTHERS THEN
    ROLLBACK;
        -- Log error
        LOG_ERROR('USP_MASTEREMPLOYEEROLE_INSERTUPDATE', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END USP_MASTEREMPLOYEEROLE_INSERTUPDATE;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERLEAVE_CREATEUPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERLEAVE_CREATEUPDATE" 
(
 p_id  IN INT,
 p_Leavetype IN VARCHAR2,
 p_Capdays IN NUMBER,
 p_basicpayded IN NUMBER DEFAULT 0.0,
 p_taded IN NUMBER DEFAULT 0.0,
 p_daded IN NUMBER DEFAULT 0.0,
 p_Deductiontype IN VARCHAR2 DEFAULT NULL,
 p_Deductionperc IN NUMBER DEFAULT NULL,
 p_ModifiedBy IN VARCHAR2 DEFAULT NULL,
 p_CreatedBy IN VARCHAR2 DEFAULT NULL
)AS
v_params CLOB := 'p_id:' || p_id;
BEGIN
    MERGE INTO MasterLeave  L
    USING DUAL ON (L.ID = P_ID)
    WHEN MATCHED THEN
        UPDATE 
        SET 
            L.leavetype = p_Leavetype,
            L.capdays=p_capdays,
          --  L.deductiontype=p_deductiontype,
           -- L.Deductionperc=p_Deductionperc,
            L.basicpayded=p_basicpayded,
            L.taded=p_taded,
            L.daded=p_daded,
            L.modifiedby = NVL(p_modifiedby, 'Unknown'),  -- Default to 'Unknown' if ModifiedBy is NULL
            L.modifieddate = SYSDATE 
   WHEN NOT MATCHED THEN
        -- Insert operation (for p_Id = 0 or NULL)
        INSERT (
            leavetype,
            capdays,
            deductiontype,
            Deductionperc,
            basicpayded,
            taded,
            daded,
            CreatedDate,
            CreatedBy
        )
        VALUES (
            p_leavetype,
            p_capdays,
            p_deductiontype,
            p_Deductionperc,
            p_basicpayded,
            p_taded,
            p_daded,
            SYSDATE,
           NVL(p_createdby, 'Tejasvi')
        );

  COMMIT; 
  
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
        -- Log error
        LOG_ERROR('USP_MasterLeave_CreateUpdate', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
       
END USP_MasterLeave_CreateUpdate;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERLEAVE_GETALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "USP_MASTERLEAVE_GETALL" (
    p_page_no            IN INT,                -- Page number
    p_page_size          IN INT,                -- Page size
    p_page_sortColumn    IN VARCHAR2 DEFAULT NULL, -- Column to sort by (optional)
    p_page_sortDirection IN NUMBER DEFAULT NULL, -- Sort direction (optional)
    p_table_name         IN VARCHAR2,           -- Table name (dynamically passed)
    p_search_text        IN VARCHAR2 DEFAULT NULL, -- Search text (optional)
    p_cursor             OUT SYS_REFCURSOR      -- Output cursor to return results
)
AS
    v_start_row   INT;
    v_end_row     INT;
    v_sql         VARCHAR2(4000);
    v_order_by    VARCHAR2(1000);
    v_search_clause VARCHAR2(1000);
    v_params CLOB := 'Param_name:' || p_page_no;
BEGIN
    -- Calculate the start and end row for the current page
    v_start_row := (p_page_no - 1) * p_page_size + 1;
    v_end_row := p_page_no * p_page_size;

    -- Determine the ORDER BY clause dynamically based on input parameters
    IF p_page_sortColumn IS NOT NULL THEN
        IF p_page_sortDirection = 1 THEN
            v_order_by := 'ORDER BY ' || p_page_sortColumn || ' ASC';
        ELSE
            v_order_by := 'ORDER BY ' || p_page_sortColumn || ' DESC';
        END IF;
    ELSE
        v_order_by := 'ORDER BY Id';  -- Default ordering by Id if no sorting column is passed
    END IF;

    -- Construct the search filter dynamically if a search text is provided
    IF p_search_text IS NOT NULL AND LENGTH(p_search_text) > 0 THEN
        v_search_clause := 'WHERE ' || 
                           'LOWER(a.column1) LIKE LOWER(''' || '%' || p_search_text || '%'' ) OR ' ||
                           'LOWER(a.column2) LIKE LOWER(''' || '%' || p_search_text || '%'' ) OR ' ||
                           'LOWER(a.column3) LIKE LOWER(''' || '%' || p_search_text || '%'' )'; -- Add other columns as needed
    ELSE
        v_search_clause := ''; -- No search filter if no search text is provided
    END IF;

    -- Construct the dynamic SQL statement with search filter and pagination
    v_sql := 'SELECT * FROM ( ' || 
             'SELECT a.*, ROW_NUMBER() OVER (' || v_order_by || ') AS rownums ' ||
             'FROM ' || p_table_name || ' a ' || v_search_clause || ') r ' ||
             'WHERE r.rownums BETWEEN :start_row AND :end_row';

    -- Open the cursor with the dynamically constructed SQL query
    OPEN p_cursor FOR v_sql USING v_start_row, v_end_row;

EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_MasterLeave_getall', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END USP_MasterLeave_getall;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERLEVEL_CRUD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERLEVEL_CRUD" (
    p_operation IN VARCHAR2,
    p_id IN NUMBER DEFAULT NULL,
    p_levelname IN VARCHAR2 DEFAULT NULL,
    p_createddate IN DATE DEFAULT NULL,
    p_createdby IN VARCHAR2 DEFAULT NULL,
    p_modifieddate IN DATE DEFAULT NULL,
    p_modifiedby IN VARCHAR2 DEFAULT NULL,
    p_deletedby IN VARCHAR2 DEFAULT NULL,
    p_deletedtime IN DATE DEFAULT NULL,
    p_result_cursor OUT SYS_REFCURSOR
)
AS
v_params CLOB := 'p_operation:' || p_operation;
BEGIN
    IF p_operation = 'INSERT' THEN
        INSERT INTO MasterLevel (LevelName, CreatedDate, CreatedBy, IsActive, IsDeleted)
        VALUES (p_levelname, NVL(p_createddate, SYSDATE), p_createdby, 1, 0);
        COMMIT;

    ELSIF p_operation = 'UPDATE' THEN
        UPDATE MasterLevel
        SET LevelName = p_levelname,
            ModifiedDate = NVL(p_modifieddate, SYSDATE),
            ModifiedBy = p_modifiedby
        WHERE Id = p_id AND IsActive = 1 AND IsDeleted = 0;
        COMMIT;

    ELSIF p_operation = 'DELETE' THEN
        UPDATE MasterLevel
        SET IsDeleted = 1,
            DeletedBy = p_deletedby,
            DeletedTime = NVL(p_deletedtime, SYSDATE)
        WHERE Id = p_id;
        COMMIT;

    ELSIF p_operation = 'GET_ALL' THEN
        OPEN p_result_cursor FOR
        SELECT * FROM MasterLevel WHERE IsActive = 1 AND IsDeleted = 0;

    ELSIF p_operation = 'GET_BY_ID' THEN
        OPEN p_result_cursor FOR
        SELECT * FROM MasterLevel WHERE Id = p_id AND IsActive = 1 AND IsDeleted = 0;

    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Invalid operation specified');
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
        -- Log error
        LOG_ERROR('usp_MasterLevel_CRUD', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERLEVELBASICPAY_CRUD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERLEVELBASICPAY_CRUD" (
    p_operation IN VARCHAR2,
    p_id IN NUMBER DEFAULT NULL,
    p_levelid IN NUMBER DEFAULT NULL,
    p_paylevel IN VARCHAR2 DEFAULT NULL,
    p_basicpay IN NUMBER DEFAULT NULL,
    p_createddate IN DATE DEFAULT NULL,
    p_createdby IN VARCHAR2 DEFAULT NULL,
    p_modifieddate IN DATE DEFAULT NULL,
    p_modifiedby IN VARCHAR2 DEFAULT NULL,
    p_isactive IN NUMBER DEFAULT NULL,
    p_deletedby IN VARCHAR2 DEFAULT NULL,
    p_deletedtime IN DATE DEFAULT NULL,
    p_result_cursor OUT SYS_REFCURSOR
)
AS
    v_count NUMBER;
    v_params CLOB := 'p_operation:' || p_operation;
BEGIN
    IF p_operation = 'INSERT' THEN
        -- Check if the combination of LevelId, PayScale, and BasicPay already exists
        SELECT COUNT(*)
        INTO v_count
        FROM MASTERLEVELBASICPAY
        WHERE LEVELID = p_levelid
          AND LOWER(PAYSCALE) = LOWER(p_paylevel)
          AND BASICPAY = p_basicpay
          AND ISDELETED = 0;

        -- If the combination exists, raise an error
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'The values LevelId, PayScale, and BasicPay are already present in the table.');
        END IF;

        -- If no duplicate found, proceed with the insert
        INSERT INTO MASTERLEVELBASICPAY (LEVELID, PAYSCALE, BASICPAY, CREATEDDATE, CREATEDBY, ISACTIVE, ISDELETED)
        VALUES (p_levelid, p_paylevel, p_basicpay, NVL(p_createddate, SYSDATE), p_createdby, NVL(p_isactive, 1), 0);
        COMMIT;

    ELSIF p_operation = 'UPDATE' THEN
        UPDATE MASTERLEVELBASICPAY
        SET PAYSCALE = p_paylevel,
            BASICPAY = p_basicpay,
            MODIFIEDDATE = NVL(p_modifieddate, SYSDATE),
            MODIFIEDBY = p_modifiedby,
            ISACTIVE = NVL(p_isactive, ISACTIVE)
        WHERE ID = p_id AND ISDELETED = 0;
        COMMIT;

    ELSIF p_operation = 'DELETE' THEN
        UPDATE MASTERLEVELBASICPAY
        SET ISDELETED = 1,
            DELETEDBY = p_deletedby,
            DELETEDTIME = NVL(p_deletedtime, SYSDATE)
        WHERE ID = p_id;
        COMMIT;

    ELSIF p_operation = 'GET_ALL' THEN
        OPEN p_result_cursor FOR
        SELECT * FROM MASTERLEVELBASICPAY WHERE ISACTIVE = 1 AND ISDELETED = 0;

    ELSIF p_operation = 'GET_BY_PAYLEVEL' THEN
        OPEN p_result_cursor FOR
        SELECT ML.LevelName, ML.IsActive, ML.ID LevelId, PM.ID ScaleID, PayScale, BasicPay, PM.ID AS "Id" FROM 
            MasterLevel ML
        Join MASTERLEVELBASICPAY PM on ML.ID = PM.LevelID
            WHERE 
          ML.ISDELETED = 0 and PM.IsDeleted = 0
        and  LOWER(LEVELNAME) = NVL(lower(p_paylevel), LOWER(LEVELNAME))
        order by BasicPay;
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Invalid operation specified');
    END IF;

    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
        -- Log error
        LOG_ERROR('usp_MasterLevelBasicPay_CRUD', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERMENU_GETALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERMENU_GETALL" ( 
   p_rolecode  IN VARCHAR2,
   p_cursor OUT SYS_REFCURSOR
) 
AS

v_params CLOB := 'Param_name:' || p_rolecode;

BEGIN
    OPEN p_cursor FOR
        SELECT 
            m.id as "id", 
            m.name AS "displayName",
            m.icon AS "icon",
            m.url AS "url",
            m.sortorder AS "sortby",
            0 AS "count"
        FROM MASTERMENU m             
        JOIN  MASTERPERMISSION MP ON m.ID = MP.MENUID
        JOIN  MASTERROLEPERMISSION MRP ON MP.ID = MRP.PermissionID
        JOIN MASTERROLE R ON R.Id = MRP.RoleId
        WHERE m.ISACTIVE = 1 AND m.ISMENU = 1 and  MP.IsDeleted=0 AND MP.IsActive=1    
              AND MP.NAME='View' And MRP.IsDeleted=0 
              AND R.Code = p_roleCode
              AND (R.Code = 'ADM' OR m.name <> 'Masters') 
        ORDER BY m.sortorder;
  EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('USP_MasterMenu_GetAll', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERMENU_GETWIDGETS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERMENU_GETWIDGETS" (
    p_rolecode  IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) 
AS
v_params CLOB := 'p_rolecode:' || p_rolecode;
BEGIN
    OPEN p_cursor FOR
        SELECT DISTINCT m.id as "id",
            m.name AS "displayName",
            m.icon AS "icon",
            m.url AS "url",
            m.sortorder AS "sortby",
            0 AS "count"
        FROM MASTERMENU m      
        JOIN MASTERPERMISSION MP ON m.ID = MP.MENUID
        JOIN MASTERROLEPERMISSION MRP ON MP.ID = MRP.PermissionID 
        JOIN MASTERROLE R ON R.Id = MRP.RoleId
        WHERE m.ISACTIVE = 1 AND m.ISMENU = 0 AND MRP.ISACTIVE = 1 AND MP.ISACTIVE = 1
              AND MP.NAME='View' AND m.IsDisplay = 1 And MRP.IsDeleted=0
              AND R.Code = p_roleCode
        ORDER BY m.sortorder; 

    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
        -- Log error
        LOG_ERROR('USP_MasterMenu_GetWidgets', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEROFFICE_CREATEUPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEROFFICE_CREATEUPDATE" (
    p_id               IN NUMBER DEFAULT NULL ,          -- Use NUMBER instead of INT
    p_officecode        IN VARCHAR2,
    p_officename        IN VARCHAR2,
    p_address1          IN VARCHAR2 DEFAULT NULL,
    p_address2          IN VARCHAR2 DEFAULT NULL,
    p_cityid            IN NUMBER DEFAULT NULL,  -- Use NUMBER for INT
    p_stateid           IN NUMBER DEFAULT NULL,  -- Use NUMBER for INT
    p_pinno             IN VARCHAR2 DEFAULT NULL,  -- Use NUMBER for INT
    p_tno               IN VARCHAR2 DEFAULT NULL,
    p_webaddress        IN VARCHAR2 DEFAULT NULL,
    p_professionaltax   IN VARCHAR2 DEFAULT NULL,
    p_email             IN VARCHAR2 DEFAULT NULL,
    p_mobile            IN VARCHAR2 DEFAULT NULL,
    p_dicofficetypeid   IN VARCHAR2 DEFAULT NULL,  
    p_parentofficeId    IN VARCHAR2 DEFAULT NULL,
    p_officetype        IN VARCHAR2 DEFAULT NULL,
    p_isactive          IN VARCHAR2 DEFAULT NULL,
    p_createdby         IN VARCHAR2 DEFAULT NULL,
    p_modifiedby        IN VARCHAR2 DEFAULT NULL,
    p_bankname          IN VARCHAR2 DEFAULT NULL,
    p_bankaccountno     IN VARCHAR2 DEFAULT NULL,
    p_ifsccode         IN VARCHAR2 DEFAULT NULL,
    p_branchname      IN VARCHAR2 DEFAULT NULL
   
) AS
    v_office_id NUMBER;  -- Variable to hold the inserted Office ID
    v_params CLOB := 'p_id:' || p_id;
BEGIN

    IF p_id > 0 THEN
        -- Update operation for MASTEROFFICE
        UPDATE MASTEROFFICE
        SET
            officecode = p_officecode,
            officename = p_officename,
            --officetypeid=p_officetypeid,
            dicOfficeTypeId = p_dicOfficeTypeId,
            parentOfficeId=p_parentOfficeId,
            email = p_email,
            mobileno = p_mobile,
            telephonenumber = p_tno,  
            webaddress = p_webaddress,
            Professionaltax=p_professionaltax,
            bankname=p_bankname,   
            bankaccountno=p_bankaccountno,
            ifsccode=p_ifsccode,  
            branchname=p_branchname,  
            isactive = p_isactive, 
            modifiedby = NVL(p_modifiedby, 'Unknown'),  -- Default to 'Unknown' if ModifiedBy is NULL
            modifieddate = SYSDATE 
        WHERE Id = p_id ;  -- Check for '1' for active records in VARCHAR2

        IF SQL%ROWCOUNT = 0 THEN
            -- If no rows are affected, raise an error
            RAISE_APPLICATION_ERROR(-20001, 'Record not found for update');
        END IF;

        -- Update corresponding MASTERADDRESS table
        UPDATE MASTERADDRESS
        SET
            address1 = p_address1,
            address2 = p_address2,
            cityid = p_cityid,
            stateid = p_stateid,
            pin = p_pinno,
            modifieddate = SYSDATE,
            modifiedby = NVL(p_modifiedby, 'Unknown')  -- Default to 'Unknown' if ModifiedBy is NULL
        WHERE tablekey = p_id AND tablename = 'MasterOffice';  -- Use the tablekey and tablename for the foreign key

        IF SQL%ROWCOUNT = 0 THEN
            -- If no rows are affected (i.e., no record exists in MASTERADDRESS), insert the data
            INSERT INTO MASTERADDRESS (
                Tablekey,
                tablename,  
                address1,
                address2,
                cityid,
                stateid,
                pin,
                createddate,
                createdby
            )
            VALUES (
                p_id,  -- Use the given office ID
                'MasterOffice',  -- Set the tablename to 'MasterOffice'
                p_address1,
                p_address2,
                p_cityid,
                p_stateid,
                p_pinno,
                SYSDATE,
                NVL(p_createdby, 'Tejasvi')  -- Default created by user is 'Tejasvi'
            );
        END IF;
    COMMIT;
    ELSE
        -- Insert operation (for p_id = 0 or NULL) for MASTEROFFICE
        INSERT INTO MASTEROFFICE (
            officecode,
            officename,
            --officetypeid,
            dicOfficeTypeId,
            email,
            mobileno,
            telephonenumber,
            webaddress,
            parentOfficeId,
            isactive,
            createddate,
            createdby,
            professionaltax,
            bankname,   
            bankaccountno, 
            ifsccode, 
            branchname   
        )
        VALUES (
            p_officecode,
            p_officename,
            --NVL(p_officetypeid,1),
            p_dicOfficeTypeId,
            p_email,
            p_mobile,
            p_tno,  -- Correct variable for telephonenumber
            p_webaddress,
            p_parentOfficeId,
            '1',  -- Active (assuming '1' for active)
            SYSDATE,
            NVL(p_createdby, 'Tejasvi'),  -- Default created by user is 'Tejasvi'
            p_professionaltax,
            p_bankname  ,    
            p_bankaccountno , 
            p_ifsccode  ,    
            p_branchname   
        )
        RETURNING Id INTO v_office_id;  -- Capture the generated ID of the newly inserted office

        -- Now insert into MASTERADDRESS table with the generated office ID
        INSERT INTO MASTERADDRESS (
            Tablekey,
            tablename,  
            address1,
            address2,
            cityid,
            stateid,
            pin,
            createddate,
            createdby
        )
        VALUES (
            v_office_id,  
            'MasterOffice',  -- Set the tablename to 'MasterOffice'
            p_address1,
            p_address2,
            p_cityid,
            p_stateid,
            p_pinno,
            SYSDATE,
            NVL(p_createdby, 'Tejasvi')  -- Default created by user is 'Tejasvi'
        );
    END IF;

    -- Commit once at the end of the entire transaction
    COMMIT;  -- Commit the transaction

    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
        -- Log error
        LOG_ERROR('USP_MASTEROFFICE_CREATEUPDATE', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END USP_MASTEROFFICE_CREATEUPDATE;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEROFFICE_GETALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEROFFICE_GETALL" (
    p_empCode           IN VARCHAR2 DEFAULT NULL,
    p_dicofficetypeid    IN INT DEFAULT NULL,     
    p_parentofficeid     IN INT DEFAULT NULL,     
    p_pageno             IN INT DEFAULT NULL,          -- Default to page 1 if not provided
    p_pagesize           IN INT DEFAULT NULL,         -- Default to 10 records per page
    p_searchtext         IN VARCHAR2 DEFAULT NULL,
    p_cursor             OUT SYS_REFCURSOR
) AS
    P_OFFICECODE  INT;
    v_value       VARCHAR2(50);
    v_params      CLOB := 'Param_name:' || p_empCode;

BEGIN
    -- Ensure employee code is provided
    IF p_empCode IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employee code cannot be null');
    END IF;

    -- Get office code for the provided employee code
    BEGIN
        SELECT e.officeid INTO P_OFFICECODE
        FROM MASTEREMPLOYEE e 
        WHERE e.EmployeeCode = p_empCode AND e.Isdeleted=0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Employee code not found.');
    END;

    -- Get office type ID for the provided office code
    BEGIN
        SELECT dicofficetypeid INTO v_value 
        FROM masteroffice 
        WHERE id = P_OFFICECODE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Office not found.');
    END;

    -- If the office type ID is 1, nullify the office code
    IF v_value = 1 THEN
        P_OFFICECODE := NULL;
    END IF;

    DBMS_OUTPUT.put_line('Office Code: ' || P_OFFICECODE);
    DBMS_OUTPUT.put_line('p_dicofficetypeid: ' || p_dicofficetypeid);
    -- Open the cursor with the query for pagination using CTE
    OPEN p_cursor FOR
    WITH CTE AS 
    (
        SELECT 
            ms.Id AS "id",
            ms.officecode AS "officeCode", 
            ms.officename AS "officeName",
            ms.OfficeCode || ' - ' || ms.OfficeName AS "displayName",
            ms.officetypeid AS "officetypeid",
            ms.parentofficeid AS "parentofficeid",
            ms.dicofficetypeid AS "dicofficetypeid",
            mo1.officename AS "parentoffice",
            DIC.VALUE AS "officetype",
            ma.address1 AS "address1", 
            ma.address2 AS "address2", 
            ma.stateid AS "stateid",
            ma.cityid AS "cityid",
            ma.pin AS "PinNo",
            ms.email AS "email",
            ms.mobileno AS "mobile",
            ms.telephonenumber AS "tno", 
            mct.name AS "name",
            mst.statename AS "statename",
            ms.webaddress AS "webaddress", 
            ms.professionaltax AS "professionaltax",
            ms.createdby,
            ms.modifiedby,
            ms.IsDeleted,
            ms.Deletedby,
            ms.IsActive AS "IsActive",
            ROW_NUMBER() OVER (ORDER BY DIC.NumId, Mst.StateName, Ms.OfficeName) AS rownums
        FROM MasterOffice ms
        LEFT JOIN MasterAddress ma ON ms.ID = ma.tablekey AND ma.TableName = 'MasterOffice'
        LEFT JOIN MasterSTATE Mst ON ma.Stateid = mst.ID
        LEFT JOIN MASTERCITY MCT ON ma.cityid = mct.ID
        LEFT JOIN Dictionary DIC ON ms.DicOfficeTypeId = DIC.NumId AND Dic.Code = 'OFFICE_TYPE'
        LEFT JOIN MASTEROFFICE MO1 ON MO1.Id = ms.parentofficeid
        WHERE ms.IsDeleted = 0 AND ms.IsActive = 1
              AND (MS.Id = NVL(p_officecode, MS.Id) OR ms.parentofficeid = NVL(p_officecode, ms.parentofficeid))
              AND (p_searchtext IS NULL OR LOWER(ms.officename) LIKE '%' || LOWER(p_searchtext) || '%' OR LOWER(ms.officecode) LIKE '%' || LOWER(p_searchtext) || '%')  -- Optional search filter
              AND (p_dicofficetypeid IS NULL OR ms.dicofficetypeid = p_dicofficetypeid)  -- Filter for office type ID
              AND (p_parentofficeid IS NULL OR ms.parentofficeid = p_parentofficeid)  -- Filter for parent office ID
 )
    SELECT (SELECT COUNT(1) FROM CTE) AS "totalCount", CTE.*
    FROM CTE
    WHERE CTE.rownums BETWEEN ((p_pageno - 1) * p_pagesize + 1) AND (p_pageno * p_pagesize)
    ORDER BY CTE.rownums;

EXCEPTION
    WHEN OTHERS THEN
        -- Log error if any exception occurs
        LOG_ERROR('usp_Masteroffice_getall', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
        RAISE;
END usp_Masteroffice_getall;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEROFFICE_GETALL1
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEROFFICE_GETALL1" (
    p_empCode           IN VARCHAR2 DEFAULT NULL,
    p_dicofficetypeid    IN INT DEFAULT NULL,     
    p_parentofficeid     IN INT DEFAULT NULL,     
    p_pageno             IN INT DEFAULT NULL,          -- Default to page 1 if not provided
    p_pagesize           IN INT DEFAULT NULL,         -- Default to 10 records per page
    p_searchtext         IN VARCHAR2 DEFAULT NULL,
    p_cursor             OUT SYS_REFCURSOR
) AS
    P_OFFICECODE  INT;
    v_value       VARCHAR2(50);
    v_params      CLOB := 'Param_name:' || p_empCode;

BEGIN
    -- Ensure employee code is provided
    IF p_empCode IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employee code cannot be null');
    END IF;

    -- Get office code for the provided employee code
    BEGIN
        SELECT e.officeid INTO P_OFFICECODE
        FROM MASTEREMPLOYEE e 
        WHERE e.EmployeeCode = p_empCode AND e.Isdeleted=0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Employee code not found.');
    END;

    -- Get office type ID for the provided office code
    BEGIN
        SELECT dicofficetypeid INTO v_value 
        FROM masteroffice 
        WHERE id = P_OFFICECODE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Office not found.');
    END;

    -- If the office type ID is 1, nullify the office code
    IF v_value = 1 THEN
        P_OFFICECODE := NULL;
    END IF;

    DBMS_OUTPUT.put_line('Office Code: ' || P_OFFICECODE);
    DBMS_OUTPUT.put_line('p_dicofficetypeid: ' || p_dicofficetypeid);
    -- Open the cursor with the query for pagination using CTE
    OPEN p_cursor FOR
    WITH CTE AS 
    (
        SELECT 
            ms.Id AS "id",
            ms.officecode AS "officeCode", 
            ms.officename AS "officeName",
            ms.OfficeCode || ' - ' || ms.OfficeName AS "displayName",
            ms.officetypeid AS "officetypeid",
            ms.parentofficeid AS "parentofficeid",
            ms.dicofficetypeid AS "dicofficetypeid",
            mo1.officename AS "parentoffice",
            DIC.VALUE AS "officetype",
            ma.address1 AS "address1", 
            ma.address2 AS "address2", 
            ma.stateid AS "stateid",
            ma.cityid AS "cityid",
            ma.pin AS "PinNo",
            ms.email AS "email",
            ms.mobileno AS "mobile",
            ms.telephonenumber AS "tno", 
            mct.name AS "name",
            mst.statename AS "statename",
            ms.webaddress AS "webaddress", 
            ms.professionaltax AS "professionaltax",
            ms.createdby,
            ms.modifiedby,
            ms.IsDeleted,
            ms.Deletedby,
            ms.IsActive AS "IsActive",
            ROW_NUMBER() OVER (ORDER BY DIC.NumId, Mst.StateName, Ms.OfficeName) AS rownums
        FROM MasterOffice ms
        LEFT JOIN MasterAddress ma ON ms.ID = ma.tablekey AND ma.TableName = 'MasterOffice'
        LEFT JOIN MasterSTATE Mst ON ma.Stateid = mst.ID
        LEFT JOIN MASTERCITY MCT ON ma.cityid = mct.ID
        LEFT JOIN Dictionary DIC ON ms.DicOfficeTypeId = DIC.NumId AND Dic.Code = 'OFFICE_TYPE'
        LEFT JOIN MASTEROFFICE MO1 ON MO1.Id = ms.parentofficeid
        WHERE ms.IsDeleted = 0 AND ms.IsActive = 1
            AND (
                -- If p_parentofficeID is provided, match ID or ParentOfficeID
                (p_parentofficeid IS NOT NULL AND (ms.ID = p_parentofficeid OR ms.parentofficeid = p_parentofficeid))  
                -- If p_parentofficeID is NULL, apply filter on officetypeid
                OR (p_parentofficeid IS NULL AND ms.dicofficetypeid = p_dicofficetypeid)
            )
             -- AND (MS.Id = NVL(p_officecode, MS.Id) )  
             AND (p_searchtext IS NULL OR LOWER(ms.officename) LIKE '%' || LOWER(p_searchtext) || '%' OR LOWER(ms.officecode) LIKE '%' || LOWER(p_searchtext) || '%')  -- Optional search filter
 )
    SELECT (SELECT COUNT(1) FROM CTE) AS "totalCount", CTE.*
    FROM CTE
    WHERE CTE.rownums BETWEEN ((p_pageno - 1) * p_pagesize + 1) AND (p_pageno * p_pagesize)
    ORDER BY CTE.rownums;

EXCEPTION
    WHEN OTHERS THEN
        -- Log error if any exception occurs
        LOG_ERROR('usp_Masteroffice_getall', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
        RAISE;
END usp_Masteroffice_getall1;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEROFFICE_GETALLBACKUP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEROFFICE_GETALLBACKUP" (
    p_page_no            IN INT DEFAULT NULL,                
    p_page_size          IN INT DEFAULT NULL,            
    p_page_sortColumn    IN VARCHAR2 DEFAULT NULL, 
    p_page_sortDirection IN NUMBER DEFAULT NULL, 
    p_table_name         IN VARCHAR2 DEFAULT NULL,    
    p_cursor      OUT SYS_REFCURSOR    
) AS
    v_sql               VARCHAR2(4000);
    v_order_by_clause   VARCHAR2(4000);
BEGIN  
       OPEN p_cursor FOR 
       
              SELECT 
              ms.Id,
              ms.officecode, ms.officename, ms.officetypeid, ma.address1, ma.address2, 
              ma.stateid, ma.cityid, ma.pin as PinNo, ms.email, ms.mobileno as mobile, ms.telephonenumber as tno, 
              mct.name,
              mst.statename,
              ms.webaddress, ms.professionaltax,
              ms.createdby,
              ms.modifiedby,
              ms.IsDeleted,
              ms.Deletedby,
              ms.IsActive
              FROM MasterOffice ms
              LEFT JOIN MasterAddress ma ON ms.ID = ma.tablekey 
              LEFT JOIN MAsterSTATE Mst on ma.Stateid=mst.ID
              LEFT JOIN MASTERCITY MCT on ma.cityid=mct.ID
              WHERE ms.ISDELETED = 0;

END usp_Masteroffice_getallbackup;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEROFFICE_GETALLBYDICOFICETYPEID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEROFFICE_GETALLBYDICOFICETYPEID" (
    p_Id    IN NUMBER DEFAULT NULL,     
    p_cursor             OUT SYS_REFCURSOR
) AS
 

BEGIN

    OPEN p_cursor FOR
     SELECT 
            ms.Id AS "id",
            ms.officecode AS "officeCode", 
            ms.officename AS "officeName",
            ms.OfficeCode || ' - ' || ms.OfficeName AS "displayName",
            ms.officetypeid AS "officetypeid",
            ms.parentofficeid AS "parentofficeid",
            ms.dicofficetypeid AS "dicofficetypeid",
            mo1.officename AS "parentoffice",
            DIC.VALUE AS "officetype",
            ma.address1 AS "address1", 
            ma.address2 AS "address2", 
            ma.stateid AS "stateid",
            ma.cityid AS "cityid",
            ma.pin AS "PinNo",
            ms.email AS "email",
            ms.mobileno AS "mobile",
            ms.telephonenumber AS "tno", 
            mct.name AS "name",
            mst.statename AS "statename",
            ms.webaddress AS "webaddress", 
            ms.professionaltax AS "professionaltax",
            ms.createdby,
            ms.modifiedby,
            ms.IsDeleted,
            ms.Deletedby,
            ms.IsActive AS "IsActive",
            ROW_NUMBER() OVER (ORDER BY DIC.NumId, Mst.StateName, Ms.OfficeName) AS rownums
        FROM MasterOffice ms
        LEFT JOIN MasterAddress ma ON ms.ID = ma.tablekey AND ma.TableName = 'MasterOffice'
        LEFT JOIN MasterSTATE Mst ON ma.Stateid = mst.ID
        LEFT JOIN MASTERCITY MCT ON ma.cityid = mct.ID
        LEFT JOIN Dictionary DIC ON ms.DicOfficeTypeId = DIC.NumId AND Dic.Code = 'OFFICE_TYPE'
        LEFT JOIN MASTEROFFICE MO1 ON MO1.Id = ms.parentofficeid
        WHERE ms.IsDeleted = 0 AND ms.IsActive = 1
              --AND (MS.Id = NVL(p_officecode, MS.Id) OR ms.parentofficeid = NVL(p_officecode, ms.parentofficeid))
             -- AND (p_searchtext IS NULL OR LOWER(ms.officename) LIKE '%' || LOWER(p_searchtext) || '%' OR LOWER(ms.officecode) LIKE '%' || LOWER(p_searchtext) || '%')  -- Optional search filter
              AND (p_Id IS NULL OR ms.dicofficetypeid = p_Id);  -- Filter for office type ID
            --  AND (p_parentofficeid IS NULL OR ms.parentofficeid = p_parentofficeid)  -- Filter for parent office ID


EXCEPTION
    WHEN OTHERS THEN
        -- Log error if any exception occurs
        LOG_ERROR('usp_Masteroffice_getallbydicoficetypeid', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK,'');
        RAISE;
END usp_Masteroffice_getallbydicoficetypeid;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEROFFICE_GETALLTEST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEROFFICE_GETALLTEST" (
    p_page_no            IN INT DEFAULT NULL,                
    p_page_size          IN INT DEFAULT NULL,            
   
    p_cursor      OUT SYS_REFCURSOR    
) AS
    v_sql               VARCHAR2(4000);
    v_order_by_clause   VARCHAR2(4000);
BEGIN  
       OPEN p_cursor FOR 

              SELECT 
              ms.Id,
              ms.officecode, ms.officename, ms.officetypeid, ma.address1, ma.address2, 
              ma.stateid, ma.cityid, ma.pin as PinNo, ms.email, ms.mobileno as mobile, ms.telephonenumber as tno, 
              mct.name,
              mst.statename,
              ms.webaddress, ms.professionaltax,
              ms.createdby,
              ms.modifiedby,
              ms.IsDeleted,
              ms.Deletedby,
              ms.IsActive
              FROM MasterOffice ms
              LEFT JOIN MasterAddress ma ON ms.ID = ma.tablekey 
              LEFT JOIN MAsterSTATE Mst on ma.Stateid=mst.ID
              LEFT JOIN MASTERCITY MCT on ma.cityid=mct.ID
              WHERE ms.ISDELETED = 0;

END usp_Masteroffice_getalltest;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEROFFICE_GETALLTEST1
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEROFFICE_GETALLTEST1" (
    p_pageno            IN INT DEFAULT NULL,                
    p_pagesize          IN INT DEFAULT NULL,            
    p_cursor            OUT SYS_REFCURSOR    
) AS
    v_sql               VARCHAR2(4000);
    v_order_by_clause   VARCHAR2(4000);
BEGIN  
    OPEN p_cursor FOR 
     WITH filtered_data AS 
     (
              SELECT 
              ms.Id as "id",
              ms.officecode as "officeCode", 
              ms.officename as "officeName",
              ms.officetypeid as "officetypeid",
              ma.address1 as "address1", 
              ma.address2 as "address2", 
              ma.stateid as "stateid",
              ma.cityid as "cityid",
              ma.pin as "PinNo",
              ms.email as "email",
              ms.mobileno as "mobile",
              ms.telephonenumber as "tno", 
              mct.name as "name",
              mst.statename as  "statename",
              ms.webaddress as "webaddress", 
              ms.professionaltax as "professionaltax",
              ms.createdby,
              ms.modifiedby,
              ms.IsDeleted,
              ms.Deletedby,
              ms.IsActive as "IsActive"
              FROM MasterOffice ms
              INNER JOIN MasterAddress ma ON ms.ID = ma.tablekey 
              INNER JOIN MAsterSTATE Mst on ma.Stateid=mst.ID
              INNER JOIN MASTERCITY MCT on ma.cityid=mct.ID
              WHERE ms.ISDELETED = 0
          )
           SELECT 
                (SELECT COUNT(*) FROM filtered_data) AS "totalCount", 
              "id",
              "officeCode", "officeName", "officetypeid","address1", "address2", 
              "stateid", "cityid", "PinNo", "email", 
              "mobile",
              "tno", 
              "name",
              "statename",
              "webaddress",
              "professionaltax",
              --createdby,
             -- modifiedby,
             --IsDeleted,
             --Deletedby,
              "IsActive"
            FROM 
                filtered_data;
                
END usp_Masteroffice_getalltest1;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEROFFICE_GETBYID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEROFFICE_GETBYID" (
    p_id            IN INT DEFAULT NULL, 
    p_table_name    IN VARCHAR2 DEFAULT NULL,
    p_cursor      OUT SYS_REFCURSOR    
) AS
    v_sql               VARCHAR2(4000);
    v_order_by_clause   VARCHAR2(4000);
    v_params CLOB := 'P_ID:' || P_ID;
BEGIN  
       OPEN p_cursor FOR 

              SELECT 
              ms.Id as "id",
              ms.officecode as "officecode",
              ms.officename as "officename", 
              ms.officetypeid as "officetypeid", 
              ma.address1 as "address1",
              ma.address2 as "address2", 
              ma.stateid as "stateId" ,
              ma.cityid as "cityId", 
              ma.pin as "pinNo", 
              ms.email as "email" ,
              ms.mobileno as "mobile",
              ms.telephonenumber as "tno", 
              mct.name as "name",
              mst.statename as "statename",
              ms.webaddress as "webaddress",
              ms.professionaltax as "professionaltax",
              ms.parentofficeid as "parentofficeid",
              ms.dicofficetypeid as "dicofficetypeid",
              ms.bankname  as "bankname" ,   
              ms.bankaccountno as "bankaccountno"  ,
              ms. ifsccode as "ifsccode"  ,   
              ms.branchname as "branchname" , 
              mo1.officename AS "parentoffice",
              DIC.VALUE AS "officetype",
             -- ms.createdby,
              ms.createddate as "createddate",
              ms.modifiedby as "modifiedby",
              ms.modifieddate as "modifieddate",
              ms.IsDeleted as "isdeleted",
              ms.Deletedby as "Deletedby",
              ms.deleteddate as "deleteddate",
              ms.IsActive as "isactive"
              FROM MasterOffice ms
              LEFT JOIN MasterAddress ma ON ms.ID = ma.tablekey  AND ma.TableName = 'MasterOffice'
              --INNER JOIN Dictionary DIC  ON ms.DicOfficeTypeId = DIC.Id 
              LEFT JOIN MAsterSTATE Mst on ma.Stateid=mst.ID
              LEFT JOIN MASTERCITY MCT on ma.cityid=mct.ID
              LEFT JOIN Dictionary DIC ON ms.DicOfficeTypeId = DIC.NumId AND Dic.Code = 'OFFICE_TYPE'
              LEFT JOIN MASTEROFFICE MO1 ON MO1.Id = ms.parentofficeid 
              --AND ms.isactive = '1' 
              where ms.Id = NVL(p_id, MS.id) AND ms.IsDeleted=0;
            
    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
        -- Log error
        LOG_ERROR('usp_Masteroffice_getbyid', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);

END usp_Masteroffice_getbyid;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTEROFFICE_GETPARENTOFFICEID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTEROFFICE_GETPARENTOFFICEID" (     
    p_id IN NUMBER,
    p_pageno IN NUMBER DEFAULT NULL,
    p_pagesize IN NUMBER DEFAULT NULL,
    p_cursor       OUT SYS_REFCURSOR    
) AS
v_params CLOB := 'P_ID:' || P_ID;

BEGIN  
    OPEN p_cursor FOR 
        SELECT DISTINCT MO.OFFICECODE as "officecode",
                 MO.OFFICENAME as "officename",
                 d.VALUE AS "officetype",
                 MO.dicofficetypeid AS "dicofficetypeid",
                 mo.officename AS "parentoffice",
                 mo.Id AS "parentofficeid"
         FROM MASTEROFFICE MO
         LEFT JOIN Dictionary d  ON MO.DicOfficeTypeId = d.NumId AND Code = 'OFFICE_TYPE'
         WHERE  MO.DicOfficeTypeId < p_id
         AND mo.IsActive = 1;
        -- LEFT JOIN MASTEROFFICE MO1 on MO1.Id = MO.parentofficeid 
        -- WHERE DIC.VALUE !='HV School' AND MO.dicofficetypeid = p_id; 

        EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
        -- Log error
        LOG_ERROR('usp_Masteroffice_GetParentofficeId', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);


END usp_Masteroffice_GetParentofficeId;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERPERMISSION_GETUSERPERMISSION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERPERMISSION_GETUSERPERMISSION" (
    p_roleCode      IN VARCHAR2 DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
          SELECT 
           -- MP.MENUID,
            MS.Controller AS "menu",
            MS.Name as "name",
            MS.URL AS "url",
            MAX(CASE WHEN MP.name = 'View' THEN 1 ELSE 0 END) AS "view",
            MAX(CASE WHEN MP.name = 'Create' THEN 1 ELSE 0 END) AS "create",
            MAX(CASE WHEN MP.name = 'Update' THEN 1 ELSE 0 END) AS "update",
            MAX(CASE WHEN MP.name = 'ApproveReject' THEN 1 ELSE 0 END) AS "approveReject",
            MAX(CASE WHEN MP.name = 'Delete' THEN 1 ELSE 0 END) AS "delete"
        FROM MASTERMENU MS
        INNER JOIN MASTERPERMISSION MP ON MS.ID = MP.MENUID
        INNER JOIN MASTERROLEPERMISSION MRP ON MP.ID = MRP.PermissionID
        INNER JOIN MASTERROLE R ON R.Id = MRP.RoleId AND R.Code = p_roleCode
        WHERE MP.IsActive=1 AND MS.IsActive=1 AND MRP.IsActive = 1  
        AND MRP.ISDELETED=0 AND MP.IsDeleted=0
        GROUP BY MS.Controller, MS.URL, MS.Name;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERPERMISSION_GETUSERPERMISSIONALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERPERMISSION_GETUSERPERMISSIONALL" (
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
          SELECT 
           -- MP.MENUID,
            MS.Controller AS "menu",
            MS.URL AS "url",
            MAX(CASE WHEN MP.name = 'View' AND (MRP.ID !=0) THEN 1 ELSE 0 END) AS "view",
            MAX(CASE WHEN MP.name = 'Create' AND (MRP.ID !=0) THEN 1 ELSE 0 END) AS "create",
            MAX(CASE WHEN MP.name = 'Update' AND (MRP.ID !=0) THEN 1 ELSE 0 END) AS "update",
            MAX(CASE WHEN MP.name = 'ApproveReject'  AND (MRP.ID !=0) THEN 1 ELSE 0 END) AS "approveReject",
            MAX(CASE WHEN MP.name = 'Delete' AND (MRP.ID !=0) THEN 1 ELSE 0 END) AS "delete",
            MP.IsActive AS "isActive"
        FROM 
            MASTERMENU MS
        INNER JOIN 
            MASTERPERMISSION MP ON MS.ID = MP.MENUID
        LEFT JOIN     
            MASTERROLEPERMISSION MRP ON MP.ID = MRP.PermissionID
            WHERE MP.IsDeleted=0 AND MRP.IsDeleted=0
        GROUP BY 
           -- MP.MENUID,
            MS.Controller, MS.URL,MP.isActive;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERROLE_CREATEUPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "USP_MASTERROLE_CREATEUPDATE" (
    p_Id           IN INT,
    p_RoleName     IN VARCHAR2,
    p_IsActive     IN VARCHAR2,
    p_CreatedDate  IN DATE DEFAULT NULL,
    p_createdby    IN VARCHAR2 DEFAULT NULL,
    p_ModifiedBy   IN VARCHAR2 DEFAULT NULL,
    p_ModifiedDate IN DATE DEFAULT NULL
) AS
BEGIN
    IF p_Id > 0 THEN
        -- Update operation
        UPDATE MasterRole
        SET
            RoleName = p_RoleName,
            IsActive = p_IsActive,
            ModifiedBy = NVL(p_ModifiedBy, 'Unknown'), -- Default to 'Unknown' if ModifiedBy is NULL
            ModifiedDate = NVL(p_ModifiedDate, SYSDATE) -- Use provided ModifiedDate or current timestamp
        WHERE Id = p_Id ;

        IF SQL%ROWCOUNT = 0 THEN
            -- If no rows are affected, it means the record doesn't exist
            RAISE_APPLICATION_ERROR(-20001, 'Record not found for update');
        END IF;

    ELSE
        -- Insert operation (for p_Id = 0 or NULL)
        INSERT INTO MasterRole (
            RoleName,
            IsActive,
            CreatedBy,
            CreatedDate
        )
        VALUES (
            p_RoleName,
            p_IsActive,
             NVL(p_createdby, 'Unknown'), -- Assuming 'Tejasvi' is the user performing the insert
            SYSDATE   -- Automatically insert current timestamp for CreatedDate
        );
    END IF;

    COMMIT;  -- Commit the transaction
END usp_masterrole_createupdate;

/
--------------------------------------------------------
--  DDL for Procedure USP_MASTERSTATE_GETALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_MASTERSTATE_GETALL" (
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    
    SELECT ID, CODE, STATENAME, ISACTIVE, CREATEDDATE, CREATEDBY, MODIFIEDDATE, MODIFIEDBY
    FROM MasterState
    WHERE ISACTIVE = 1
    ORDER BY STATENAME;

EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        LOG_ERROR('usp_MasterState_GetAll', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, 'no_parameter');  
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_PAYBILL_OFFICEEMPLOYEE_ALLOWANCE_CREATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_PAYBILL_OFFICEEMPLOYEE_ALLOWANCE_CREATE" (
    p_id IN NUMBER,
    --p_officecode IN VARCHAR2,
    --p_month IN VARCHAR2,
    --p_year IN VARCHAR2,
    p_actionby IN VARCHAR2
) AS

V_DA NUMBER;
V_TA NUMBER;
V_DAONTA NUMBER;
V_HRA NUMBER;
V_NPSMGT NUMBER;
V_CPFMGT NUMBER;

BEGIN
        SELECT NVL((VALUE/100),0) INTO V_DAONTA FROM DICTIONARY WHERE CODE = 'DEARNESS_ALLOWANCE';

        -- pay bill allowance
        INSERT INTO paybillallowance (
            PayBillEmployeeId, DEARNESSALLOWANCE, 
            TRANSPORTALLOWANCE, DAONTRANSPORTALL0WANCE,HOUSERENTALLOWANCEDHRA,
            NPSMGTSHARE,CPFMGTSHARE,ADDITIONALHRA,CreatedDate,CreatedBy
        )
        SELECT PBE.Id,
            UDF_Calculate_DA(PBE.EmployeeCode,PBE.BasicPay) AS DearnessAllowance, --ME.BasicPay * V_DA AS DearnessAllowance, 
            UDF_GetEmployeeTA(PBE.EmployeeCode) AS TransportAllowance, --V_TA AS TransportAllowance, 
            UDF_GetEmployeeTA(PBE.EmployeeCode) * V_DAONTA AS DaOnTransportAllowance, 
            UDF_Calculate_HRA(PBE.EmployeeCode) AS HouseRentAllowance, --ME.BasicPay * (HRA/100) AS HouseRentAllowance,
            (CASE WHEN SCHEMETYPE = 0 THEN UDF_Calculate_NPSMGT_SHARE(PBE.EmployeeCode,PBE.BasicPay) ELSE 0 END) AS NpsMgtShare, --(ME.BasicPay + (ME.BasicPay * V_DA)) * V_NPSMGT AS NpsMgtShare,
            (CASE WHEN SCHEMETYPE = 2 THEN UDF_Calculate_CPFMGT_SHARE(PBE.EmployeeCode,PBE.BasicPay) ELSE 0 END) AS CpfMgtShare, --ME.BasicPay * V_CPFMGT AS CpfMgtShare, 
            NVL(UDF_Calculate_AddtionalHRA(PBE.EmployeeCode),0) ADDITIONALHRA,
            SYSDATE, 
            p_actionby
            FROM 
            PayBillEmployee PBE 
            INNER JOIN MasterEmployee ME ON PBE.EmployeeCode=ME.EmployeeCode
            INNER JOIN MasterOffice mo on mo.id=me.OFFICEID
            INNER JOIN MasterAddress ma on ma.TableKey=mo.id and ma.TableName='MasterOffice'
            INNER JOIN MasterCity mc on mc.id=ma.cityid
            INNER JOIN MasterCityCategory mcc on mcc.id=mc.MASTERCITYCATEGORYID
            WHERE PBE.PAYBILLMAINID=p_id;
        
    COMMIT;
    
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_PAYBILL_OFFICEEMPLOYEE_CREATEUPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_PAYBILL_OFFICEEMPLOYEE_CREATEUPDATE" (
    p_jsondata IN CLOB, -- JSON array of objects as input
    p_actionby IN VARCHAR2,
    p_officecode IN VARCHAR2 DEFAULT NULL,
    p_year IN VARCHAR2,    
    p_month IN VARCHAR2,
    p_id IN NUMBER
) AS
    v_main_id  NUMBER(20,0); -- Variable to store LeaveEntryMain ID    
    v_paybill_employee_id NUMBER(20,0);
    v_paybill_status_id  NUMBER(10,0);
BEGIN

    BEGIN
        SELECT Id INTO v_paybill_status_id
        FROM Dictionary
        WHERE Code = 'PAYBILL_STATUS' AND Value = 'Pending'
        FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Pending leave status not found in Dictionary.');
    END;
    -- Process each record in the JSON input
    FOR r IN (
    SELECT jt.Id AS id,
           jt.PayBillMainId AS paybillmainid,
           jt.EmployeeCode AS employeecode,
           jt.TotalDays AS totaldays,
           jt.TotalPresentDays AS totalpresentdays,
           jt.NumberOfPostSanctioned AS numberofpostsanctioned,
           jt.StaffInPosition AS staffinposition,
           jt.TotalAllowance AS totalallowance,
           jt.TotalDeduction AS totaldeduction,
           jt.FinalAmount AS FinalAmount,
           jt.PayBillAllowanceId AS paybillallowanceid,
           jt.PayBillEmployeeId AS paybillemployeeid,
           jt.DeputationAllowance AS deputationallowance,
           jt.CashHandlingTreasuryAllowance AS cashhandlingtreasuryallowance,
           jt.HighAltitudeAllowance AS highaltitudeallowance,
           jt.HardAreaAllowance AS hardareaallowance,
           jt.IslandSpecialDutyAllowance AS islandspecialdutyallowance,
           jt.SpecialDutyAllowance AS specialdutyallowance,
           jt.ToughLocationAllowance1 AS toughlocationallowance1,
           jt.ToughLocationAllowance2 AS toughlocationallowance2,
           jt.ToughLocationAllowance3 AS toughlocationallowance3,
           jt.SecondShiftAllowance AS secondshiftallowance,
           jt.LsAndPcProjectKvs AS lsandpcprojectKvs,
           jt.OtherAllowance AS otherallowance,
           jt.DressAllowance AS dressallowance,               
           jt.PayBillDeductionId AS paybilldeductionid,
           jt.LicenceFeeOutsideAg AS licencefeeoutsideag,
           jt.ElectricWaterChargesOutsideAg AS electricwaterchargesoutsideag,
           jt.CoOpSociety AS coopsociety,
           jt.ConvAdvInterestRec AS convsdvinterestrec,
           jt.CairInstallment AS cairinstallment,
           jt.HbaInterest AS housebuildingadvanceinterest,
           jt.HbaiInstallment AS hbaiinstallment,
           jt.PmCaresFund AS primeministercaresfund,
           jt.OtherRemittances AS otherremittances,
           jt.GpfRecovery AS gpfrecovery,
           jt.GpfAdvRecovery AS gpfadvrecovery,
           jt.GpfInstallment AS gpfinstallment,
           jt.CpfOwnShare AS cpfownshare,
           jt.CpfMgtShare AS cpfmgtshare,
           jt.CpfAdvRecovery AS cpfadvrecovery,
           jt.CpfInstallment AS cpfinstallment,
           jt.KvsEmpWelfareScheme AS kvsemployeeswelfarescheme,
           jt.HplRecovery AS hplrecovery,
           jt.LicenceFeeKvsBldg AS licencefeekvsbuilding,
           jt.ElectricWaterCharge AS electricwatercharge,
           jt.RecOfOverPayment AS recofoverpayment,
           jt.CghsRecovery AS cghsrecovery,
           jt.OtherDeductions AS otherdeductions,
           jt.Status AS status,
           jt.RoStatus AS rostatus,          
           jt.HoStatus AS hostatus
    FROM JSON_TABLE(
        p_jsondata,
        '$[*]'
        COLUMNS (
            Id NUMBER(20,0) PATH '$.Id',
            PayBillMainId  NUMBER(20,0) PATH '$.PayBillMainId',
            EmployeeCode VARCHAR2(50) PATH '$.EmployeeCode',
            TotalDays NUMBER(10,0) PATH '$.TotalDays',
            TotalPresentDays NUMBER(5,1) PATH '$.TotalPresentDays',
            NumberOfPostSanctioned NUMBER PATH '$.NumberOfPostSanctioned',
            StaffInPosition NUMBER PATH '$.StaffInPosition',
            TotalAllowance NUMBER(20,2) PATH '$.TotalAllowance',
            TotalDeduction NUMBER(20,2) PATH '$.TotalDeduction',
            FinalAmount NUMBER(20,2) PATH '$.FinalAmount',
            PayBillAllowanceId NUMBER(20,0) PATH '$.PayBillAllowanceId',
            PayBillEmployeeId NUMBER(20,0) PATH '$.PayBillEmployeeId',
            DeputationAllowance NUMBER(20,2) PATH '$.DeputationAllowance',
            CashHandlingTreasuryAllowance NUMBER(20,2) PATH '$.CashHandlingTreasuryAllowance',
            HighAltitudeAllowance NUMBER(20,2) PATH '$.HighAltitudeAllowance',
            HardAreaAllowance NUMBER(20,2) PATH '$.HardAreaAllowance',
            IslandSpecialDutyAllowance NUMBER(20,2) PATH '$.IslandSpecialDutyAllowance',
            SpecialDutyAllowance NUMBER(20,2) PATH '$.SpecialDutyAllowance',
            ToughLocationAllowance1 NUMBER(20,2) PATH '$.ToughLocationAllowance1',
            ToughLocationAllowance2 NUMBER(20,2) PATH '$.ToughLocationAllowance2',
            ToughLocationAllowance3 NUMBER(20,2) PATH '$.ToughLocationAllowance3',
            SecondShiftAllowance NUMBER(20,2) PATH '$.SecondShiftAllowance',
            LsAndPcProjectKvs NUMBER(20,2) PATH '$.LsAndPcProjectKvs',
            OtherAllowance NUMBER(20,2) PATH '$.OtherAllowance',
            DressAllowance NUMBER(20,2) PATH '$.DressAllowance',
            PayBillDeductionId NUMBER(20,0) PATH '$.PayBillDeductionId',
            LicenceFeeOutsideAg NUMBER(20,2) PATH '$.LicenceFeeOutsideAg',
            ElectricWaterChargesOutsideAg NUMBER(20,2) PATH '$.ElectricWaterChargesOutsideAg',
            CoOpSociety NUMBER(20,2) PATH '$.CoOpSociety',
            ConvAdvInterestRec NUMBER(20,2) PATH '$.ConvAdvInterestRec',
            CairInstallment NUMBER(20,0) PATH '$.CairInstallment',
            HbaInterest NUMBER(20,2) PATH '$.HbaInterest',
            HbaiInstallment NUMBER(20,0) PATH '$.HbaiInstallment',
            PmCaresFund NUMBER(20,2) PATH '$.PmCaresFund',
            OtherRemittances NUMBER(20,2) PATH '$.OtherRemittances',
            GpfRecovery NUMBER(20,2) PATH '$.GpfRecovery',
            GpfAdvRecovery NUMBER(20,2) PATH '$.GpfAdvRecovery',
            GpfInstallment NUMBER(20,0) PATH '$.GpfInstallment',
            CpfOwnShare NUMBER(20,2) PATH '$.CpfOwnShare',
            CpfMgtShare NUMBER(20,2) PATH '$.CpfMgtShare',
            CpfAdvRecovery NUMBER(20,2) PATH '$.CpfAdvRecovery',
            CpfInstallment NUMBER(20,0) PATH '$.CpfInstallment',
            KvsEmpWelfareScheme NUMBER(20,2) PATH '$.KvsEmpWelfareScheme',
            HplRecovery NUMBER(20,2) PATH '$.HplRecovery',
            LicenceFeeKvsBldg NUMBER(20,2) PATH '$.LicenceFeeKvsBldg',
            ElectricWaterCharge NUMBER(20,2) PATH '$.ElectricWaterCharge',
            RecOfOverPayment NUMBER(20,2) PATH '$.RecOfOverPayment',
            CghsRecovery NUMBER(20,2) PATH '$.CghsRecovery',
            OtherDeductions NUMBER(20,2) PATH '$.OtherDeductions',
            Status NUMBER(10,0) PATH '$.Status',
            RoStatus NUMBER(10,0) PATH '$.RoStatus',
            HoStatus NUMBER(10,0) PATH '$.HoStatus'
        )
    ) jt
)
LOOP
            
            -- Update an existing record based on ID
            UPDATE PayBillAllowance
            SET
                DEPUTATIONALLOWANCE=NVL(r.deputationallowance,0),
                CASHHANDLINGTREASURYALLOWANCE=NVL(r.cashhandlingtreasuryallowance,0),
                HIGHALTITUDEALLOWANCE=NVL(r.highaltitudeallowance,0),
                HARDAREAALLOWANCE=NVL(r.hardareaallowance,0),
                ISLANDSPECIALDUTYALLOWANCE=NVL(r.islandspecialdutyallowance,0),
                SPECIALDUTYALLOWANCE=NVL(r.specialdutyallowance,0),
                TOUGHLOCATIONALLOWANCE1=NVL(r.toughlocationallowance1,0),
                TOUGHLOCATIONALLOWANCE2=NVL(r.toughlocationallowance2,0),
                TOUGHLOCATIONALLOWANCE3=NVL(r.toughlocationallowance3,0),
                SECONDSHIFTALLOWANCE=NVL(r.secondshiftallowance,0),
                LSANDPCPROJECTKVS=NVL(r.lsandpcprojectKvs,0),
                OTHERALLOWANCE=NVL(r.otherallowance,0),
                DRESSALLOWANCE=NVL(r.dressallowance,0),
                ModifiedDate = SYSDATE,
                ModifiedBy = p_actionby
            WHERE Id = r.paybillallowanceid;            
            commit;
           
 
-------------for income tax updation-----------------

            UPDATE PayBillDeduction
                  SET INCOMETAX = UDF_Employee_IncomeTax(r.paybillemployeeid)
                  WHERE Id = r.paybilldeductionid;
            COMMIT;
            
            -- Update an existing record based on ID
            UPDATE PayBillDeduction
            SET
                LicenceFeeOutsideAgency=NVL(r.licencefeeoutsideag,0),
                ElectricWaterChargesOutsideAgency=NVL(r.electricwaterchargesoutsideag,0),
                CoOpSociety=NVL(r.coopsociety,0),
                ConvAdvInterestRecovery=NVL(r.convsdvinterestrec,0),
                CairInstallmentNo=NVL(r.cairinstallment,0),
                HouseBuildingAdvanceInterest=NVL(r.housebuildingadvanceinterest,0),
                HbaiInstallmentNo=NVL(r.hbaiinstallment,0),
                PrimeMinisterCaresFund=NVL(r.primeministercaresfund,0),
                OtherRemittances=NVL(r.otherremittances,0),
                GpfRecovery=0,
                GpfAdvanceRecovery=NVL(r.gpfadvrecovery,0),
                GpfInstalmentNo=NVL(r.gpfinstallment,0),
                CpfRecoveryOwnShare=NVL(r.cpfownshare,0),
                CpfRecoveryMgtShare=NVL(r.cpfmgtshare,0),
                CpfAdvRecovery=NVL(r.cpfadvrecovery,0),
                CpfInstallmentNo=NVL(r.cpfinstallment,0),
                KvsEmployeesWelfareScheme=NVL(r.kvsemployeeswelfarescheme,0),
                LSANDPCPROJECTKVS=NVL(r.lsandpcprojectKvs,0),
                HplRecovery=NVL(r.hplrecovery,0),
                LicenceFeesKvsBuilding=NVL(r.licencefeekvsbuilding,0),
                ElectricWaterCharges=NVL(r.electricwatercharge,0),
                RecOfOverPayment=NVL(r.recofoverpayment,0),
                CGHSRECOVERY=NVL(r.cghsrecovery,0),
                OTHERDEDUCTIONS=NVL(r.otherdeductions,0),
                ModifiedDate = SYSDATE,
                ModifiedBy = p_actionby
            WHERE Id = r.paybilldeductionid;           
            commit;
           
        UPDATE paybillemployee
            SET
                NUMBEROFPOSTSANCTIONED =NVL(r.numberofpostsanctioned,0),
                STAFFINPOSITION=NVL(r.staffinposition,0),
                DICSTATUSID = NVL(r.status,0),
                DICROSTATUSID = NVL(r.rostatus,0),
                DICHOSTATUSID = NVL(r.hostatus,0),
                ModifiedDate = SYSDATE,
                ModifiedBy = p_actionby
            WHERE Id = r.paybillemployeeid;
            commit;

-------------------TOTALALLOWANCE-----------------------

          
Merge into PayBillEmployee c
using (select * from paybillemployee a inner join 
        paybillallowance b on a.id=b.PayBillEmployeeId
        where a.id=r.paybillemployeeid
) d on (c.id=d.PayBillEmployeeId)
when matched then 
   update set
          c.TotalAllowance = (NVL(d.BasicPay,0) + NVL(d.DEPUTATIONALLOWANCE,0) + NVL(d.DEARNESSALLOWANCE,0) + NVL(d.TRANSPORTALLOWANCE,0) 
          + NVL(d.DAONTRANSPORTALL0WANCE,0) + NVL(d.HOUSERENTALLOWANCEDHRA,0) + NVL(d.NPSMGTSHARE,0) + NVL(d.CPFMGTSHARE,0) 
          + NVL(d.CASHHANDLINGTREASURYALLOWANCE,0) + NVL(d.HIGHALTITUDEALLOWANCE,0) + NVL(d.HARDAREAALLOWANCE,0) 
          + NVL(d.ISLANDSPECIALDUTYALLOWANCE,0) + NVL(d.SPECIALDUTYALLOWANCE,0) + NVL(d.TOUGHLOCATIONALLOWANCE1,0) 
          + NVL(d.TOUGHLOCATIONALLOWANCE2,0) + NVL(d.TOUGHLOCATIONALLOWANCE3,0) + NVL(d.SECONDSHIFTALLOWANCE,0) 
          + NVL(d.LSANDPCPROJECTKVS,0) + NVL(d.OTHERALLOWANCE,0) + NVL(d.DRESSALLOWANCE,0) + NVL(d.ADDITIONALHRA,0) );
            commit;


  
-------------------TOTALDEDUCTION--------------------------
  
Merge into PayBillEmployee c
using (select * from paybillemployee a inner join 
        paybilldeduction b on a.id=b.PayBillEmployeeId
        where a.id=r.paybillemployeeid
) d on (c.id=d.PayBillEmployeeId)
when matched then 
   update set
          c.TotalDeduction = (NVL(d.INCOMETAX,0) + NVL(d.PROFESSIONALTAX,0) + NVL(d.LICENCEFEEOUTSIDEAGENCY,0) 
          + NVL(d.ELECTRICWATERCHARGESOUTSIDEAGENCY,0)
            + NVL(d.NPSOWNSHARE,0) + NVL(d.NPSMGTSHARE,0) + NVL(d.COOPSOCIETY,0) + NVL(d.CONVADVINTERESTRECOVERY,0) 
            + NVL(d.HOUSEBUILDINGADVANCEINTEREST,0) + NVL(d.PRIMEMINISTERCARESFUND,0) + NVL(d.OTHERREMITTANCES,0)
            + NVL(d.GPFRECOVERY,0) + NVL(d.GPFADVANCERECOVERY,0) + NVL(d.CPFRECOVERYOWNSHARE,0)
            + NVL(d.CPFRECOVERYMGTSHARE,0) + NVL(d.CPFADVRECOVERY,0) + NVL(d.KVSEMPLOYEESWELFARESCHEME,0)
            + nvl(d.LSANDPCPROJECTKVS,0) + NVL(d.HPLRECOVERY,0) + NVL(d.LICENCEFEESKVSBUILDING,0) + NVL(d.ELECTRICWATERCHARGES,0)
            + NVL(d.RECOFOVERPAYMENT,0) + NVL(d.CGHSRECOVERY,0) + NVL(d.OTHERDEDUCTIONS,0));
            commit;
 
UPDATE paybillemployee
    SET FinalAmount = (TotalAllowance - TotalDeduction)
    where id = r.paybillemployeeid;
            commit;
    
    END LOOP;
  
    -- Here update Employee Table for TotalDeduction, TotalAllowance And FinalAmount

    -- Commit changes
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_PAYBILL_OFFICEEMPLOYEE_DEDUCTION_CREATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_PAYBILL_OFFICEEMPLOYEE_DEDUCTION_CREATE" (
    p_id IN NUMBER,
    --p_officecode IN VARCHAR2,
    --p_month IN VARCHAR2,
    --p_year IN VARCHAR2,
    p_actionby IN VARCHAR2
) AS
V_INTX NUMBER;
V_PTX NUMBER;
V_NPSMGT NUMBER;
V_NPSOWN NUMBER;
V_DA NUMBER;
BEGIN
        SELECT NVL((VALUE/100),0) INTO V_INTX FROM DICTIONARY WHERE CODE = 'INCOME_TAX';
       -- pay bill allowance
        INSERT INTO paybilldeduction (
                PAYBILLEMPLOYEEID,INCOMETAX,PROFESSIONALTAX,
                NPSOWNSHARE,NPSMGTSHARE,CPFRECOVERYOWNSHARE,CPFRECOVERYMGTSHARE,GPFRECOVERY,
                CreatedDate,CreatedBy
            )
        SELECT PBE.Id, 
        0 AS IncomeTax,
        200 AS ProfessionalTax, 
        (CASE WHEN SCHEMETYPE = 0 THEN UDF_Calculate_NPSOWN_SHARE(PBE.EmployeeCode,PBE.BasicPay) ELSE 0 END) AS NpsOwnShare, --(ME.BasicPay + (ME.BasicPay * V_DA)) * V_NPSOWN AS NpsOwnShare, 
        (CASE WHEN SCHEMETYPE = 0 THEN UDF_Calculate_NPSMGT_SHARE(PBE.EmployeeCode,PBE.BasicPay) ELSE 0 END) AS NpsMgtShare, --(ME.BasicPay + (ME.BasicPay * V_DA)) * V_NPSMGT AS NpsMgtShare, 
        (CASE WHEN SCHEMETYPE = 2 THEN CPFOWNSHARE ELSE 0 END) CPFRECOVERYOWNSHARE,
        (CASE WHEN SCHEMETYPE = 2 THEN UDF_Calculate_CPFMGT_SHARE(PBE.EmployeeCode,PBE.BasicPay) ELSE 0 END) CPFRECOVERYMGTSHARE,
        (CASE WHEN SCHEMETYPE = 1 THEN GPFOWNSHARE ELSE 0 END) GPFRECOVERY,
        SYSDATE,
        p_actionby
        FROM PayBillEmployee PBE 
        INNER JOIN MASTEREMPLOYEE ME ON ME.EMPLOYEECODE=PBE.EMPLOYEECODE
        WHERE PBE.PAYBILLMAINID=p_id;

    COMMIT;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_PAYBILL_OFFICEEMPLOYEE_TOTAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_PAYBILL_OFFICEEMPLOYEE_TOTAL" (
    p_id IN NUMBER,
    --p_officecode IN VARCHAR2,
    --p_month IN VARCHAR2,
    --p_year IN VARCHAR2,
    p_actionby IN VARCHAR2
) AS

BEGIN

-------------------TOTALALLOWANCE-----------------------

Merge into PayBillEmployee c
using (select * from paybillemployee a inner join 
        paybillallowance b on a.id=b.PayBillEmployeeId
        where paybillmainid=p_id
) d on (c.id=d.PayBillEmployeeId)
when matched then 
   update set
          c.TotalAllowance = (NVL(d.BasicPay,0) + NVL(d.DEPUTATIONALLOWANCE,0) + NVL(d.DEARNESSALLOWANCE,0) + NVL(d.TRANSPORTALLOWANCE,0) 
          + NVL(d.DAONTRANSPORTALL0WANCE,0) + NVL(d.HOUSERENTALLOWANCEDHRA,0) + NVL(d.NPSMGTSHARE,0) + NVL(d.CPFMGTSHARE,0) 
          + NVL(d.CASHHANDLINGTREASURYALLOWANCE,0) + NVL(d.HIGHALTITUDEALLOWANCE,0) + NVL(d.HARDAREAALLOWANCE,0) 
          + NVL(d.ISLANDSPECIALDUTYALLOWANCE,0) + NVL(d.SPECIALDUTYALLOWANCE,0) + NVL(d.TOUGHLOCATIONALLOWANCE1,0) 
          + NVL(d.TOUGHLOCATIONALLOWANCE2,0) + NVL(d.TOUGHLOCATIONALLOWANCE3,0) + NVL(d.SECONDSHIFTALLOWANCE,0) 
          + NVL(d.LSANDPCPROJECTKVS,0) + NVL(d.OTHERALLOWANCE,0) + NVL(d.DRESSALLOWANCE,0) );

-------------------TOTALDEDUCTION--------------------------

Merge into PayBillEmployee c
using (select * from paybillemployee a inner join 
        paybilldeduction b on a.id=b.PayBillEmployeeId
        where paybillmainid=p_id
) d on (c.id=d.PayBillEmployeeId)
when matched then 
   update set
          c.TotalDeduction = (NVL(d.INCOMETAX,0) + NVL(d.PROFESSIONALTAX,0) + NVL(d.LICENCEFEEOUTSIDEAGENCY,0) 
          + NVL(d.ELECTRICWATERCHARGESOUTSIDEAGENCY,0)
            + NVL(d.NPSOWNSHARE,0) + NVL(d.NPSMGTSHARE,0) + NVL(d.COOPSOCIETY,0) + NVL(d.CONVADVINTERESTRECOVERY,0) 
            + NVL(d.HOUSEBUILDINGADVANCEINTEREST,0) + NVL(d.PRIMEMINISTERCARESFUND,0) + NVL(d.OTHERREMITTANCES,0)
            + NVL(d.GPFRECOVERY,0) + NVL(d.GPFADVANCERECOVERY,0) + NVL(d.CPFRECOVERYOWNSHARE,0)
            + NVL(d.CPFRECOVERYMGTSHARE,0) + NVL(d.CPFADVRECOVERY,0) + NVL(d.KVSEMPLOYEESWELFARESCHEME,0)
            + nvl(d.LSANDPCPROJECTKVS,0) + NVL(d.HPLRECOVERY,0) + NVL(d.LICENCEFEESKVSBUILDING,0) + NVL(d.ELECTRICWATERCHARGES,0)
            + NVL(d.RECOFOVERPAYMENT,0) + NVL(d.CGHSRECOVERY,0) + NVL(d.OTHERDEDUCTIONS,0));
        

UPDATE paybillemployee
    SET FinalAmount = (TotalAllowance - TotalDeduction)
    where paybillmainid = p_id;


    COMMIT;

END;

/
--------------------------------------------------------
--  DDL for Procedure USP_PAYBILL_UPSERTEMPLOYEE_LEAVES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_PAYBILL_UPSERTEMPLOYEE_LEAVES" 
(
    v_leavemainid IN NUMBER,  
    p_actionby IN VARCHAR2                
)
AS
    v_pbMainId NUMBER;
BEGIN
    -- Insert into PayBillMain if it does not exist
    INSERT INTO PayBillMain (OfficeCode, Year, Month, DICSTATUSID, CreatedBy, CreatedDate)
    SELECT lm.officecode, lm.Year, lm.Month, 1, p_actionby, SYSDATE
    FROM LeaveEntryMain lm WHERE lm.Id = v_leavemainid
    AND NOT EXISTS (
        SELECT 1 FROM PayBillMain pb 
        WHERE pb.OfficeCode = lm.OfficeCode 
        AND pb.Year = lm.Year 
        AND pb.Month = lm.Month
    );

  DBMS_OUTPUT.PUT_LINE('v_pbMainId :');
  
    -- Get ID from last insert and pass it next insert statement 
    SELECT pb.Id
    INTO v_pbMainId
    FROM LeaveEntryMain lm --WHERE lm.Id = v_leavemainid
    JOIN PayBillMain pb ON  pb.OfficeCode = lm.OfficeCode AND pb.Year = lm.Year AND pb.Month = lm.Month
    where lm.id=v_leavemainid;      

DBMS_OUTPUT.PUT_LINE('v_pbMainId :' || v_pbMainId);

    -- Insert into PayBillEmployee
    INSERT INTO PayBillEmployee (
        PayBillMainId, EmployeeCode, EmployeeName, EmployeeDesignation, 
        LevelName, TotalDays, TotalPresentDays, BasicPay, 
        TotalAllowance, TotalDeduction, FinalAmount, DICSTATUSID,
        CreatedBy, CreatedDate
    )
    SELECT DISTINCT
        pb.ID AS PayBillMainId,
        le.EMPLOYEECODE,
        COALESCE(me.FullName, 'Unknown') AS EmployeeName,  
        COALESCE(md.Name, 'Unknown') AS EmployeeDesignation,  
        COALESCE(ml.LevelName, 'Unknown') AS LevelName,  
        GetMonthDays(pb.month, pb.year) AS TotalDays, -- 30, --COALESCE(SUM(le.LEAVEDAYS), 30) AS TotalDays,  
        UDF_Leave_Summary(le.EMPLOYEECODE,pb.year,pb.month) AS BasicPay,
       -- 30,  SUM(le.LEAVEDAYS) AS TotalPresentDays,  
        UDF_Calculate_Leave_Deduction(le.EMPLOYEECODE,pb.month,pb.year) AS BasicPay,
        0 AS TotalAllowance,  
        0 AS TotalDeduction,  
        0 AS FinalAmount,  
        pb.DICSTATUSID,
        p_actionby AS CreatedBy,  
        SYSDATE AS CreatedDate 
    FROM LeaveEntry le 
    JOIN LeaveEntryMain lm ON le.LEAVEENTRYMAINID = lm.ID 
    JOIN PayBillMain pb    ON pb.Id = v_pbMainId  AND pb.OfficeCode = lm.OfficeCode 
        --ON pb.OfficeCode = lm.OfficeCode AND pb.Year = lm.Year AND pb.Month = lm.Month
    LEFT JOIN MasterEmployee me ON me.EmployeeCode = le.EMPLOYEECODE
    LEFT JOIN MasterLevel   ml ON ml.ID = me.LevelID  
    LEFT JOIN MasterDesignation md ON md.ID = me.DesignationID
    WHERE le.DICLEAVESTATUSID = 5 AND lm.DICSTATUSID = 5
    AND NOT EXISTS (SELECT 1 FROM PayBillEmployee pb1 
        WHERE pb1.EmployeeCode = le.EMPLOYEECODE
        AND pb1.PayBillMainId = v_pbMainId 
    ); -- Approved

    -- Final commit after inserting both tables
    
     usp_PayBill_OfficeEmployee_Allowance_Create(v_pbMainId,p_actionby);
     usp_PayBill_OfficeEmployee_Deduction_Create(v_pbMainId,p_actionby);
     USP_PAYBILL_OFFICEEMPLOYEE_TOTAL(v_pbMainId,p_actionby);
     USP_PaybillMain_Update_TotalSummary(v_pbMainId);
    
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        Dbms_Output.put_line ( DBMS_UTILITY.FORMAT_ERROR_STACK() );
        Dbms_Output.put_line ( DBMS_UTILITY.FORMAT_ERROR_BACKTRACE() );
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_PAYBILLDEDUCTION_CRUD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_PAYBILLDEDUCTION_CRUD" (
    p_json_input IN CLOB,
    p_actionby IN VARCHAR2
)
AS
    v_paybillemployeeid NUMBER;
    v_data_count NUMBER;
BEGIN
    -- Insert or update PayBillDeduction based on JSON input
    FOR rec IN (
        SELECT *
        FROM JSON_TABLE(p_json_input, '$[*]'
            COLUMNS (
                id NUMBER PATH '$.id',
                paybillemployeeid NUMBER PATH '$.payBillEmployeeId',
                incometax NUMBER PATH '$.incomeTax',
                professionaltax NUMBER PATH '$.professionalTax',
                licencefeeoutsideagency NUMBER PATH '$.licenceFeeOutsideAgency',
                electricwaterchargesoutsideagency NUMBER PATH '$.electricWaterChargesOutsideAgency',
                npsownshare NUMBER PATH '$.npsOwnShare',
                npsmgtshare NUMBER PATH '$.npsMgtShare',
                coopsociety NUMBER PATH '$.coOpSociety',
                convadvinterestrecovery NUMBER PATH '$.convAdvInterestRecovery',
                cairinstallmentno NUMBER PATH '$.cairInstallmentNo',
                housebuildingadvanceinterest NUMBER PATH '$.houseBuildingAdvanceInterest',
                hbaiinstallmentno NUMBER PATH '$.hbaiInstallmentNo',
                primeministercaresfund NUMBER PATH '$.primeMinisterCaresFund',
                otherremittances NUMBER PATH '$.otherRemittances',
                gpfrecovery NUMBER PATH '$.gpfRecovery',
                gpfadvancerecovery NUMBER PATH '$.gpfAdvanceRecovery',
                gpfinstalmentno NUMBER PATH '$.gpfInstalmentNo',
                cpfrecoveryownshare NUMBER PATH '$.cpfRecoveryOwnShare',
                cpfrecoverymgtshare NUMBER PATH '$.cpfRecoveryMgtShare',
                cpfadvrecovery NUMBER PATH '$.cpfAdvRecovery',
                cpfinstallmentno NUMBER PATH '$.cpfInstallmentNo',
                kvsemployeeswelfarescheme NUMBER PATH '$.kvsEmployeesWelfareScheme',
                lsandpcprojectkvs NUMBER PATH '$.lsAndPcProjectKvs',
                hplrecovery NUMBER PATH '$.hplRecovery',
                licencefeeskvsbuilding NUMBER PATH '$.licenceFeesKvsBuilding',
                electricwatercharges NUMBER PATH '$.electricWaterCharges',
                recofoverpayment NUMBER PATH '$.recOfOverPayment',
                cghsrecovery NUMBER PATH '$.cghsRecovery',
                otherdeductions NUMBER PATH '$.otherDeductions'
            )
        )
    ) LOOP
        -- Check if PayBillDeduction record exists
        SELECT COUNT(*) INTO v_data_count
        FROM PayBillDeduction
        WHERE ID = rec.id;

        -- If exists, update; otherwise, insert
        IF v_data_count > 0 THEN
            UPDATE PayBillDeduction
            SET 
                INCOMETAX = rec.incometax,
                PROFESSIONALTAX = rec.professionaltax,
                LICENCEFEEOUTSIDEAGENCY = rec.licencefeeoutsideagency,
                ELECTRICWATERCHARGESOUTSIDEAGENCY = rec.electricwaterchargesoutsideagency,
                NPSOWNSHARE = rec.npsownshare,
                NPSMGTSHARE = rec.npsmgtshare,
                COOPSOCIETY = rec.coopsociety,
                CONVADVINTERESTRECOVERY = rec.convadvinterestrecovery,
                CAIRINSTALLMENTNO = rec.cairinstallmentno,
                HOUSEBUILDINGADVANCEINTEREST = rec.housebuildingadvanceinterest,
                HBAIINSTALLMENTNO = rec.hbaiinstallmentno,
                PRIMEMINISTERCARESFUND = rec.primeministercaresfund,
                OTHERREMITTANCES = rec.otherremittances,
                GPFRECOVERY = rec.gpfrecovery,
                GPFADVANCERECOVERY = rec.gpfadvancerecovery,
                GPFINSTALMENTNO = rec.gpfinstalmentno,
                CPFRECOVERYOWNSHARE = rec.cpfrecoveryownshare,
                CPFRECOVERYMGTSHARE = rec.cpfrecoverymgtshare,
                CPFADVRECOVERY = rec.cpfadvrecovery,
                CPFINSTALLMENTNO = rec.cpfinstallmentno,
                KVSEMPLOYEESWELFARESCHEME = rec.kvsemployeeswelfarescheme,
                LSANDPCPROJECTKVS = rec.lsandpcprojectkvs,
                HPLRECOVERY = rec.hplrecovery,
                LICENCEFEESKVSBUILDING = rec.licencefeeskvsbuilding,
                ELECTRICWATERCHARGES = rec.electricwatercharges,
                RECOFOVERPAYMENT = rec.recofoverpayment,
                CGHSRECOVERY = rec.cghsrecovery,
                OTHERDEDUCTIONS = rec.otherdeductions,
                MODIFIEDBY = p_actionby,
                MODIFIEDDATE = SYSDATE
            WHERE ID = rec.id;
        ELSE
            INSERT INTO PayBillDeduction (
                PAYBILLEMPLOYEEID, INCOMETAX, PROFESSIONALTAX, LICENCEFEEOUTSIDEAGENCY,
                ELECTRICWATERCHARGESOUTSIDEAGENCY, NPSOWNSHARE, NPSMGTSHARE, COOPSOCIETY,
                CONVADVINTERESTRECOVERY, CAIRINSTALLMENTNO, HOUSEBUILDINGADVANCEINTEREST,
                HBAIINSTALLMENTNO, PRIMEMINISTERCARESFUND, OTHERREMITTANCES, GPFRECOVERY,
                GPFADVANCERECOVERY, GPFINSTALMENTNO, CPFRECOVERYOWNSHARE, CPFRECOVERYMGTSHARE,
                CPFADVRECOVERY, CPFINSTALLMENTNO, KVSEMPLOYEESWELFARESCHEME, LSANDPCPROJECTKVS,
                HPLRECOVERY, LICENCEFEESKVSBUILDING, ELECTRICWATERCHARGES, RECOFOVERPAYMENT,
                CGHSRECOVERY, OTHERDEDUCTIONS, CREATEDBY, CREATEDDATE
            )
            VALUES (
                rec.paybillemployeeid, rec.incometax, rec.professionaltax, rec.licencefeeoutsideagency,
                rec.electricwaterchargesoutsideagency, rec.npsownshare, rec.npsmgtshare, rec.coopsociety,
                rec.convadvinterestrecovery, rec.cairinstallmentno, rec.housebuildingadvanceinterest,
                rec.hbaiinstallmentno, rec.primeministercaresfund, rec.otherremittances, rec.gpfrecovery,
                rec.gpfadvancerecovery, rec.gpfinstalmentno, rec.cpfrecoveryownshare, rec.cpfrecoverymgtshare,
                rec.cpfadvrecovery, rec.cpfinstallmentno, rec.kvsemployeeswelfarescheme, rec.lsandpcprojectkvs,
                rec.hplrecovery, rec.licencefeeskvsbuilding, rec.electricwatercharges, rec.recofoverpayment,
                rec.cghsrecovery, rec.otherdeductions, p_actionby, SYSDATE
            );
        END IF;
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Backtrace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_PAYBILLEMPLOYEE_APPROVEREJECT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_PAYBILLEMPLOYEE_APPROVEREJECT" (
    p_id IN NUMBER,
    p_approveorreject IN NUMBER,
    p_comments IN VARCHAR2 DEFAULT NULL,
    p_hocomments IN VARCHAR2 DEFAULT NULL,
    p_rocomments IN VARCHAR2 DEFAULT NULL,
    p_actionby IN VARCHAR2,
    p_roleid IN NUMBER
)
AS
    v_dic_status_id NUMBER;
    v_dic_rostatus_id NUMBER;
    v_dic_hostatus_id NUMBER;
    v_PaybillMainId NUMBER;
    v_params CLOB := 'Param_name:' || p_id;
    v_count NUMBER;
BEGIN
    -- Get the current status and PayBillMainId for the employee
    SELECT PBE.DICSTATUSID, PBE.DICROSTATUSID, PBE.DICHOSTATUSID, PBE.PaybillmainId
    INTO v_dic_status_id, v_dic_rostatus_id, v_dic_hostatus_id, v_PaybillMainId
    FROM PayBillEmployee PBE
    INNER JOIN MasterEmployeeRole MER ON PBE.EmployeeCode = MER.EmployeeCode
    WHERE 
    --PBE.EmployeeCode = p_actionby
       MER.Roleid = p_roleid
      AND PBE.ID = p_id;

    -- If already approved (status 5), prevent update
    IF (v_dic_status_id = 5 OR v_dic_rostatus_id = 5 OR v_dic_hostatus_id = 5) THEN
        RAISE_APPLICATION_ERROR(-20002, 'Already Approved and cannot be modified.');
    END IF;

    -- Get the Dictionary ID for the new status (Approved/Rejected)
  SELECT NUMID
    INTO v_dic_status_id
    FROM Dictionary
    WHERE Code = 'PAYBILL_STATUS'
      AND NumId = CASE 
                    WHEN p_approveorreject IS NULL THEN 1  -- Handle Pending (NULL means Pending)
                    WHEN p_approveorreject = 1 THEN 5      -- Approved
                    ELSE 2                                 -- Rejected
                  END;


    -- Consolidate the retrieval of status IDs for DICROSTATUSID and DICHOSTATUSID
   v_dic_rostatus_id := v_dic_status_id;
   v_dic_hostatus_id := v_dic_status_id;

    -- If the role is 265, update PayBillEmployee
    IF (p_roleid = 265) THEN 
        UPDATE PayBillEmployee PBE
        SET 
            PBE.DICSTATUSID = v_dic_status_id,
            PBE.DICROSTATUSID =1,
            PBE.DICHOSTATUSID = 1,
            PBE.Comments = p_comments,
            PBE.Modifiedby = p_actionby,
            PBE.ModifiedDate = SYSDATE
        WHERE PBE.Id = p_id
          AND EXISTS (
              SELECT 1
              FROM MasterEmployeeRole MER
              WHERE PBE.EmployeeCode = MER.EmployeeCode
                AND MER.Roleid = p_roleid
          );
    ELSIF (p_roleid = 263) THEN 
        -- If the role is 263 admin, update PayBillEmployee
        UPDATE PayBillEmployee PBE
        SET 
            PBE.DICSTATUSID = v_dic_status_id,
            PBE.DICROSTATUSID = v_dic_rostatus_id,
            PBE.DICHOSTATUSID = v_dic_hostatus_id,
            PBE.Comments = p_comments,
            PBE.Hocomments=p_hocomments,
            PBE.ROComments=p_rocomments,
            PBE.Modifiedby = p_actionby,
            PBE.ModifiedDate = SYSDATE
        WHERE PBE.Id = p_id
          AND EXISTS (
              SELECT 1
              FROM MasterEmployeeRole MER
              WHERE PBE.EmployeeCode = MER.EmployeeCode
                AND MER.Roleid = p_roleid
          );
    END IF;

    -- Check if all entries have been approved or rejected, and if so, update PayBillMain
    SELECT COUNT(*)
    INTO v_count
    FROM PayBillEmployee PBE
    INNER JOIN PayBillMain PBM ON PBE.Paybillmainid = PBM.id
    INNER JOIN MasterEmployeeRole MER ON PBE.EmployeeCode = MER.EmployeeCode
    WHERE (PBE.dicstatusid < 5 OR PBE.DICROSTATUSID < 5 OR PBE.DICHOSTATUSID < 5)
      AND PBE.EmployeeCode = p_actionby 
      AND MER.Roleid = p_roleid
      AND PBE.PayBillMainId = v_PaybillMainId;

    -- If no pending records exist, update PayBillMain as approved
    IF v_count = 0 THEN
    --checker can update
        IF (p_roleid = 265) THEN 
            UPDATE PayBillMain 
            SET DICSTATUSID = 5
                --DICROSTATUSID = 1, 
                --DICHOSTATUSID = 1 -- Approved
            WHERE Id = v_PaybillMainId;    
            --admin
         ELSIF (p_roleid = 263) THEN 
             UPDATE PayBillMain 
             SET DICSTATUSID = 5,
                DICROSTATUSID = 5, 
                DICHOSTATUSID = 5 -- Approved
            WHERE Id = v_PaybillMainId; 
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- Log the error if any exception occurs
        LOG_ERROR('usp_PayBillEmployee_ApproveReject', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_STACK, v_params);
        RAISE;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_PAYBILLMAIN_GETALL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_PAYBILLMAIN_GETALL" (
    p_pageno IN NUMBER DEFAULT NULL,
    p_pagesize IN NUMBER DEFAULT NULL,
    p_officeCode IN VARCHAR2 DEFAULT NULL,
    p_year IN VARCHAR2 DEFAULT NULL,
    p_month IN VARCHAR2 DEFAULT NULL,  
    p_searchtext IN VARCHAR2 DEFAULT NULL,  
    p_cursor OUT SYS_REFCURSOR
) AS
    v_start_row     NUMBER;
    v_end_row       NUMBER;
    v_value         VARCHAR2(500);
    v_local_officeCode VARCHAR2(500);
BEGIN
    -- Calculate the start and end row for the current page
    v_start_row := (p_pageno - 1) * p_pagesize + 1;
    v_end_row := p_pageno * p_pagesize;

    -- Get the office type ID
    BEGIN
       SELECT dicofficetypeid INTO v_value 
       FROM masteroffice 
       WHERE OfficeCode = p_officeCode;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Office not found.');
    END;
  DBMS_OUTPUT.PUT_LINE('dicofficetypeid :' || v_value);
     IF v_value = '1' THEN
        v_local_officeCode := NULL;
    ELSE
        v_local_officeCode := p_officeCode; -- Assign the original officeCode if not 1
    END IF;
    
     DBMS_OUTPUT.PUT_LINE('v_local_officeCode :' || v_local_officeCode);

    -- Open cursor with the paginated result
    OPEN p_cursor FOR
        SELECT * FROM 
        (
            SELECT 
            PBM.Id AS "id",
            PBM.OfficeCode AS "officecode",
            MO.OfficeName AS "officename",
             mo1.officename AS "parentoffice",
            PBM.GrossAmount AS "grossamount",
            PBM.DeductionAmount AS "deductionamount",
            PBM.NetAmount AS "netamount",
            PBM.MONTH AS "month",
            PBM.YEAR AS "year",
            PBM.DICSTATUSId AS "dicstatusid",
            CASE
                WHEN PBM.DICSTATUSId = 5 THEN 'Approved'
                WHEN PBM.DICSTATUSId = 2 THEN 'Rejected'
                WHEN PBM.DICSTATUSId = 1 THEN 'Pending'
                ELSE ''
            END AS "status",
            CASE
                WHEN PBM.DICHOSTATUSID = 5 THEN 'Approved'
                WHEN PBM.DICHOSTATUSID = 2 THEN 'Rejected'
                WHEN PBM.DICHOSTATUSID = 1 THEN 'Pending'
                ELSE ''
            END AS "hostatus",
            CASE
                WHEN PBM.DICROSTATUSID = 5 THEN 'Approved'
                WHEN PBM.DICROSTATUSID = 2 THEN 'Rejected'
                WHEN PBM.DICROSTATUSID = 1 THEN 'Pending'
                ELSE ''
            END AS "rostatus",
            PBM.DICHOSTATUSID AS "dichostatusid",
            PBM.DICROSTATUSID AS "dicrostatusid",
            ROW_NUMBER() OVER (ORDER BY PBM.OfficeCode) AS rownums
        FROM PAYBILLMAIN PBM
        LEFT JOIN DICTIONARY DIC
            ON (DIC.NUMID = PBM.DICSTATUSID AND DIC.CODE = 'PAYBILL_STATUS') 
            OR (DIC.NUMID = PBM.DICHOSTATUSID AND DIC.CODE = 'PAYBILL_STATUS') 
            OR (DIC.NUMID = PBM.DICROSTATUSID AND DIC.CODE = 'PAYBILL_STATUS')
        LEFT JOIN MASTEROFFICE MO
            ON MO.OfficeCode = PBM.OfficeCode
       LEFT JOIN MASTEROFFICE MO1 ON MO1.Id = MO.parentofficeid
    WHERE (p_month IS NULL OR PBM.Month = p_month)
      AND (p_year IS NULL OR PBM.Year = p_year)
      AND (v_local_officeCode IS NULL OR PBM.OfficeCode = v_local_officeCode)
      AND (v_local_officeCode IS NULL OR ( MO.OfficeCode = v_local_officeCode))
      AND (p_searchtext IS NULL OR
           PBM.OfficeCode LIKE '%' || p_searchtext || '%' OR
           PBM.GrossAmount LIKE '%' || p_searchtext || '%' OR
           PBM.DeductionAmount LIKE '%' || p_searchtext || '%' OR
           PBM.NetAmount LIKE '%' || p_searchtext || '%' OR
           PBM.MONTH LIKE '%' || p_searchtext || '%' OR
           PBM.YEAR LIKE '%' || p_searchtext || '%')
    )
    WHERE rownums BETWEEN v_start_row AND v_end_row;

END USP_PayBillMain_GetAll;

/
--------------------------------------------------------
--  DDL for Procedure USP_PAYBILLMAIN_GETALLBYID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_PAYBILLMAIN_GETALLBYID" (
    p_id IN NUMBER DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
    
) AS
  
BEGIN
    -- Calculate the start and end row for the current page

    OPEN p_cursor FOR
       SELECT 
                    PBM.Id AS "id",
                    PBM.OfficeCode AS "officecode",
                    MO.OfficeName AS "officename",
                    PBM.GrossAmount AS "grossamount",
                    PBM.DeductionAmount AS "deductionamount",
                    PBM.NetAmount AS "netamount",
                    PBM.MONTH AS "month",
                    PBM.YEAR AS "year",
                    PBM.DICSTATUSId AS "dicstatusid",
                    CASE
                        WHEN PBM.DICSTATUSId = 5 THEN 'Approved'
                        WHEN PBM.DICSTATUSId = 2 THEN 'Rejected'
                        WHEN PBM.DICSTATUSId = 1 THEN 'Pending'
                        ELSE ''
                    END AS "status",
                    CASE
                        WHEN PBM.DICHOSTATUSID = 5 THEN 'Approved'
                        WHEN PBM.DICHOSTATUSID = 2 THEN 'Rejected'
                        WHEN PBM.DICHOSTATUSID = 1 THEN 'Pending'
                        ELSE ''
                    END AS "hostatus",
                    CASE
                        WHEN PBM.DICROSTATUSID = 5 THEN 'Approved'
                        WHEN PBM.DICROSTATUSID = 2 THEN 'Rejected'
                        WHEN PBM.DICROSTATUSID = 1 THEN 'Pending'
                        ELSE ''
                    END AS "rostatus",
                    PBM.DICHOSTATUSID AS "dichostatusid",
                    PBM.DICROSTATUSID AS "dicrostatusid",
                    ROW_NUMBER() OVER (ORDER BY PBM.OfficeCode) AS rownums
                FROM PAYBILLMAIN PBM
                LEFT JOIN DICTIONARY DIC
                    ON (DIC.NUMID = PBM.DICSTATUSID AND DIC.CODE = 'PAYBILL_STATUS') 
                    OR (DIC.NUMID = PBM.DICHOSTATUSID AND DIC.CODE = 'PAYBILL_STATUS') 
                    OR (DIC.NUMID = PBM.DICROSTATUSID AND DIC.CODE = 'PAYBILL_STATUS')
                LEFT JOIN MASTEROFFICE MO
                    ON MO.OfficeCode = PBM.OfficeCode
            Where PBM.Id=p_id;

END USP_PayBillMain_GetAllById;

/
--------------------------------------------------------
--  DDL for Procedure USP_PAYBILLMAIN_UPDATE_TOTALSUMMARY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_PAYBILLMAIN_UPDATE_TOTALSUMMARY" (
    p_id IN NUMBER
) AS
BEGIN
    UPDATE PAYBILLMAIN PBM
    SET 
        PBM.GrossAmount = (SELECT SUM(PBE.TotalAllowance) FROM PAYBILLEmployee PBE WHERE PBE.PAYBILLMAINID = p_id),
        PBM.DeductionAmount = (SELECT SUM(PBE.TotalDeduction) FROM PAYBILLEmployee PBE WHERE PBE.PAYBILLMAINID = p_id),
        PBM.NetAmount = (SELECT SUM(PBE.FinalAmount) FROM PAYBILLEmployee PBE WHERE PBE.PAYBILLMAINID = p_id)
    WHERE PBM.Id = p_id;

    COMMIT;
END;

/
--------------------------------------------------------
--  DDL for Procedure USP_TEST_LEAVE_ENTRY_BULK_UPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "USP_TEST_LEAVE_ENTRY_BULK_UPDATE" (
    p_json_input IN CLOB,        -- JSON array of objects as input
    p_actionby IN VARCHAR2       -- User performing the action
) AS
    v_dic_status_id NUMBER;      -- Variable to store the Dictionary ID for "LEAVE_STATUS"
BEGIN
    -- Use JSON_TABLE to parse the JSON array into relational rows
    FOR r IN (
        SELECT jt.Id AS id,
               jt.Comments AS comments,
               jt.approveOrReject AS approveOrReject
        FROM JSON_TABLE(
            p_json_input,
            '$[*]' -- Parse each element in the JSON array
            COLUMNS (
                Id             NUMBER PATH '$.id',
                Comments       VARCHAR2(500) PATH '$.comments',
                approveOrReject NUMBER PATH '$.approveOrReject'
            )
        ) jt
    ) LOOP
        -- Determine the Dictionary ID based on approveOrReject
        SELECT Id
        INTO v_dic_status_id
        FROM Dictionary
        WHERE Code = 'LEAVE_STATUS'
          AND (UPPER(Value) = UPPER(CASE 
                        WHEN r.approveOrReject = 1 THEN 'Approved'
                        WHEN r.approveOrReject = 0 THEN 'Rejected'
                      END));

        -- Update the LeaveEntry table
        UPDATE LeaveEntry
        SET DicLeaveStatusId = v_dic_status_id,
            Comments = r.comments,
            ModifiedDate = SYSDATE,
            StatusChangedBy = p_actionby
        WHERE Id = r.id;
        COMMIT;
    END LOOP;

    -- Commit the changes
    COMMIT;
    EXCEPTION
    --WHEN NO_DATA_FOUND THEN
    --    RAISE_APPLICATION_ERROR(-20001, 'LEAVE_STATUS not found in Dictionary table.');
    WHEN 
    OTHERS THEN
    ROLLBACK;
    RAISE;
END;

/
