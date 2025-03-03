--------------------------------------------------------
--  File created - Monday-February-17-2025   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Function GETMONTHDAYS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "GETMONTHDAYS" (p_month_name VARCHAR2, p_year NUMBER) 
RETURN NUMBER IS
    v_days NUMBER;
BEGIN
    SELECT EXTRACT(DAY FROM LAST_DAY(TO_DATE(p_month_name || ' ' || p_year, 'Month YYYY')))
    INTO v_days
    FROM DUAL;

    RETURN v_days;
END;

/
--------------------------------------------------------
--  DDL for Function UDF_CALCULATE_ADDTIONALHRA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_CALCULATE_ADDTIONALHRA" (p_employeecode VARCHAR2) 
RETURN NUMBER IS
    V_HRA NUMBER;
    V_Houserentallowance NUMBER;
BEGIN


 SELECT  pb.BasicPay * (HRA/100) Into V_Houserentallowance
            FROM MasterEmployee ME 
            --INNER JOIN MasterOffice mo on mo.id=me.OFFICEID
            LEFT JOIN MasterCity mc on mc.id=me.AdditionalHraCity
            LEFT JOIN MasterCityCategory mcc on mcc.id=mc.MASTERCITYCATEGORYID            
            INNER JOIN MasterLevel ml ON ME.LevelId=ml.Id
            INNER JOIN MasterLevelBasicPay pb ON me.Basicpay=pb.id
            WHERE ME.EmployeeCode = p_employeecode AND NVL(me.IsAdditionHra,0)=1;


    RETURN V_Houserentallowance;
END;

/
--------------------------------------------------------
--  DDL for Function UDF_CALCULATE_CPFMGT_SHARE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_CALCULATE_CPFMGT_SHARE" (p_employeecode VARCHAR2, p_basicpay NUMBER) 
RETURN NUMBER IS
    V_CPFMGT NUMBER;
    V_CPFMGT_SHARE NUMBER;
BEGIN

SELECT NVL((VALUE/100),0) INTO V_CPFMGT FROM DICTIONARY WHERE CODE = 'CPFMGT_SHARE';  --Basic*10


    SELECT p_basicpay * V_CPFMGT INTO V_CPFMGT_SHARE
            FROM MasterEmployee 
            WHERE EmployeeCode = p_employeecode;


    RETURN V_CPFMGT_SHARE;
END;

/
--------------------------------------------------------
--  DDL for Function UDF_CALCULATE_DA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_CALCULATE_DA" (p_employeecode VARCHAR2, p_basicpay NUMBER) 
RETURN NUMBER IS
    V_DA NUMBER;
    V_DearnessAllowance NUMBER;
BEGIN

SELECT NVL((VALUE/100),0) INTO V_DA FROM DICTIONARY WHERE CODE = 'DEARNESS_ALLOWANCE';


  SELECT  p_basicpay * V_DA INTO V_DearnessAllowance
            FROM  MasterEmployee 
            WHERE EmployeeCode = p_employeecode;


    RETURN V_DearnessAllowance;
END;

/
--------------------------------------------------------
--  DDL for Function UDF_CALCULATE_HRA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_CALCULATE_HRA" (p_employeecode VARCHAR2) 
RETURN NUMBER IS
    V_HRA NUMBER;
    V_Houserentallowance NUMBER;
BEGIN


 SELECT  pb.BasicPay * (HRA/100) Into V_Houserentallowance
            FROM MasterEmployee ME 
            INNER JOIN MasterOffice mo on mo.id=me.OFFICEID
            INNER JOIN MasterAddress ma on ma.TableKey=mo.id and ma.TableName='MasterOffice'
            INNER JOIN MasterCity mc on mc.id=ma.cityid
            INNER JOIN MasterCityCategory mcc on mcc.id=mc.MASTERCITYCATEGORYID            
            INNER JOIN MasterLevel ml ON ME.LevelId=ml.Id
            INNER JOIN MasterLevelBasicPay pb ON me.Basicpay=pb.id
            WHERE ME.EmployeeCode = p_employeecode;


    RETURN V_Houserentallowance;
END;

/
--------------------------------------------------------
--  DDL for Function UDF_CALCULATE_INCOMTAX
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_CALCULATE_INCOMTAX" (paybillemployeeid number) 
RETURN NUMBER IS
    v_total_allowance NUMBER;
    v_ctc_salary NUMBER;
    V_TAX_RATE number;
    v_income_tax number :=0;
BEGIN

select TotalAllowance into v_total_allowance from paybillemployee where id=paybillemployeeid;

v_ctc_salary := (v_total_allowance * 12);

--v_ctc_salary := 2525500;


for i in (select case when min_income =0 then min_income else (min_income-1) end as min_income,max_income,(tax_rate/100) as tax_rate,
              rank() over(order by min_income) as rank from mastertaxslab)
    loop
    
         IF v_ctc_salary <= i.max_income and i.rank=1 then
            v_income_tax := 0;
            exit;
         else  
           -- dbms_output.put_line('min_income : ' || i.min_income || ' , ' || 'max_income : ' || i.max_income || ' , ' || 'tax_rate : ' || i.tax_rate);
            v_income_tax := v_income_tax + ((case when v_ctc_salary>i.max_income then (case when i.max_income=0 then v_ctc_salary else i.max_income end) else v_ctc_salary end - i.min_income)*i.tax_rate);
            --dbms_output.put_line('v_income_tax : ' || v_income_tax);
            if v_ctc_salary < i.max_income then
               exit;
            end if;
         END IF;

end loop;

v_income_tax := v_income_tax/12;

    RETURN v_income_tax;
END;

/
--------------------------------------------------------
--  DDL for Function UDF_CALCULATE_LEAVE_DEDUCTION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_CALCULATE_LEAVE_DEDUCTION" (
        p_employee_code VARCHAR2,
        p_month VARCHAR2,   
        p_year VARCHAR2
    ) RETURN NUMBER IS
        v_basic_pay NUMBER(10,4);
        v_total_days NUMBER(10,4);
        v_daily_wage NUMBER(10,4);
        v_extra_ord_leave_days NUMBER(10,4);
        v_half_pay_leave_days NUMBER(10,4);
        v_total_deduction NUMBER(10,4) := 0;
        v_total_leavedays NUMBER := 0;
        v_deducted_basic_pay NUMBER(10,4);        
        v_final_basic_pay NUMBER(10,4) := 0;
        v_days_no NUMBER(10,4);
        v_dic_leave_type_id NUMBER;
        v_leave_type VARCHAR2(100);
        v_cap_days NUMBER(10,4);
        v_deduction_perc NUMBER(10,4);

BEGIN
    -- Fetch basic pay for the employee
    SELECT NVL(LB.basicpay, 0) 
    INTO v_basic_pay
    FROM MasterEmployee ME 
    INNER JOIN MasterLevel ML ON ME.LevelId=ML.Id 
    INNER JOIN MasterLevelBasicPay LB ON ME.BasicPay=LB.Id
    WHERE EMPLOYEECODE = p_employee_code;

    DBMS_OUTPUT.PUT_LINE('v_basic_pay :' || v_basic_pay);

    -- Fetch the total number of days in the month (assuming GetMonthDays is a valid function)
    SELECT NVL(GetMonthDays(p_month, p_year), 0)
    INTO v_total_days
    FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('v_total_days :' || v_total_days);

    -- Calculate per day wage
    v_daily_wage := NVL(v_basic_pay / v_total_days, 0);
    DBMS_OUTPUT.PUT_LINE('v_daily_wage :' || v_daily_wage);

    -- Declare cursor for leave data
    FOR leave_rec IN (
        SELECT NVL(SUM(LE.LEAVEDAYS), 0) AS DaysNo, 
               LE.DicLeaveTypeId, 
               ML.LeaveType, 
               ML.Capdays, 
               NVL(ML.BasicPayDed,0) AS BasicPayDed
        FROM LeaveEntry LE
        INNER JOIN MASTERLEAVE ML ON ML.Id = LE.DicLeaveTypeId
        WHERE LE.EMPLOYEECODE = p_employee_code
        AND LE.MONTH = p_month
        AND LE.YEAR = p_year
        GROUP BY LE.DicLeaveTypeId, ML.LeaveType, ML.Capdays, ML.BasicPayDed
    ) LOOP
        -- If capdays is greater than zero, apply cap and deduction logic
        IF leave_rec.Capdays > 0 THEN

            SELECT NVL(SUM(LE.LEAVEDAYS), 0) INTO v_total_leavedays
            FROM LeaveEntry LE
            INNER JOIN MASTERLEAVE ML ON ML.Id = LE.DicLeaveTypeId
            WHERE LE.EMPLOYEECODE = p_employee_code AND LE.DicLeaveTypeId = leave_rec.DicLeaveTypeId
            AND LE.YEAR = p_year;
            -- Apply cap on leave days if they exceed the cap
             IF v_total_leavedays > leave_rec.Capdays THEN
             -- Calculate deductions based on leave days and deduction percentage
                IF((v_total_leavedays-leave_rec.Capdays) > leave_rec.DaysNo) THEN
                    v_days_no := leave_rec.DaysNo;
                    DBMS_OUTPUT.PUT_LINE('Capdays applied: ' || v_days_no);
                    v_deducted_basic_pay := ROUND((v_days_no * v_daily_wage * (leave_rec.BasicPayDed/100) ),2);
                    v_total_deduction := v_total_deduction + v_deducted_basic_pay;
                ELSE
                -- Calculate deductions based on leave days and deduction percentage
                    v_days_no := (v_total_leavedays-leave_rec.Capdays);
                    DBMS_OUTPUT.PUT_LINE('Capdays applied: ' || v_days_no);
                    v_deducted_basic_pay := ROUND((v_days_no * v_daily_wage * (leave_rec.BasicPayDed/100) ),2);
                    v_total_deduction := v_total_deduction + v_deducted_basic_pay; -- Apply cap on leave days

                END IF;    
            END IF;
        ELSE
            SELECT ML.LeaveType INTO v_leave_type
            FROM MASTERLEAVE ML 
            WHERE ML.Id = leave_rec.DicLeaveTypeId;
            IF (LOWER(v_leave_type)=LOWER('Extra Ordinary Leave') OR LOWER(v_leave_type)=LOWER('Half Pay Leave')) THEN
                v_deducted_basic_pay := ROUND((leave_rec.DaysNo * v_daily_wage * (leave_rec.BasicPayDed/100) ),2);
                v_total_deduction := v_total_deduction + v_deducted_basic_pay; -- Apply cap on leave days
            END IF;
        END IF;
    END LOOP;

    v_final_basic_pay:= ROUND((v_basic_pay)-(v_total_deduction),2);
    -- Return the total deduction
    RETURN v_final_basic_pay;

EXCEPTION
    WHEN OTHERS THEN
        -- Handle any errors (e.g., if no data is found)
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RETURN 0;
END UDF_Calculate_Leave_Deduction;

/
--------------------------------------------------------
--  DDL for Function UDF_CALCULATE_NPSMGT_SHARE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_CALCULATE_NPSMGT_SHARE" (p_employeecode VARCHAR2, p_basicpay NUMBER) 
RETURN NUMBER IS
    V_DA NUMBER;
    V_NPSMGT NUMBER;
    V_NPSMGT_SHARE NUMBER;
BEGIN


V_DA := UDF_Calculate_DA(p_employeecode,p_basicpay);

SELECT NVL((VALUE/100),0) INTO V_NPSMGT FROM DICTIONARY WHERE CODE = 'NPSMGT_SHARE'; --basic+DA * 14


    SELECT  (p_basicpay + V_DA) * V_NPSMGT INTO V_NPSMGT_SHARE
            FROM MasterEmployee 
            WHERE EmployeeCode = p_employeecode;


    RETURN V_NPSMGT_SHARE;
END;

/
--------------------------------------------------------
--  DDL for Function UDF_CALCULATE_NPSOWN_SHARE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_CALCULATE_NPSOWN_SHARE" (p_employeecode VARCHAR2,p_basicpay NUMBER) 
RETURN NUMBER IS
    V_DA NUMBER;
    V_NPSOWN NUMBER;
    V_NPSOWN_SHARE NUMBER;
BEGIN

SELECT NVL((VALUE/100),0) INTO V_NPSOWN FROM DICTIONARY WHERE CODE = 'NPSOWN_SHARE'; --basic+DA * 10

V_DA := UDF_CALCULATE_DA(p_employeecode,p_basicpay);

    SELECT  (p_basicpay + V_DA) * V_NPSOWN INTO V_NPSOWN_SHARE
            FROM MasterEmployee 
            WHERE EmployeeCode = p_employeecode;


    RETURN V_NPSOWN_SHARE;
END;

/
--------------------------------------------------------
--  DDL for Function UDF_EMPLOYEE_INCOMETAX
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_EMPLOYEE_INCOMETAX" (paybillemployeeid NUMBER) 
RETURN NUMBER IS
    v_tax_amount NUMBER := 0;
    v_ctc_salary NUMBER;
    v_total_allowance NUMBER;
    v_taxable_income NUMBER;
    v_remain_amount NUMBER := 0;
BEGIN
    -- Fetch the total annual allowance (CTC)
    SELECT TotalAllowance INTO v_total_allowance FROM paybillemployee WHERE id = paybillemployeeid;
    v_ctc_salary := (v_total_allowance * 12);

    -- Loop through each tax slab dynamically
    FOR r IN (
        SELECT min_income, max_income, tax_rate 
        FROM mastertaxslab 
        WHERE SLAB_TYPE_ID = 1 
        ORDER BY min_income
    ) LOOP
        -- Handle last slab where max_income = 0 (indicating no upper limit)
        IF r.max_income = 0 THEN
            v_taxable_income := v_ctc_salary - r.min_income;
        ELSE
            v_taxable_income := LEAST(v_ctc_salary, r.max_income) - r.min_income;
        END IF;

        -- Ensure taxable income is positive
        IF v_taxable_income > 0 THEN
            v_tax_amount := v_tax_amount + (v_taxable_income * r.tax_rate / 100);
        END IF;
    END LOOP;

      v_tax_amount := v_tax_amount/12;


    RETURN v_tax_amount;
END;

/
--------------------------------------------------------
--  DDL for Function UDF_GETEMPLOYEEALLOWANCE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_GETEMPLOYEEALLOWANCE" (p_employeecode VARCHAR2)
RETURN NUMBER
IS
    v_BasicPaylevelId NUMBER;
    v_IsTPTACity NUMBER;
    v_Allowance NUMBER;
BEGIN


    -- Get Employee Basic Pay and City Type
            SELECT ME.LEVELID, mc.ISTPTACITY
            INTO v_BasicPaylevelId, v_IsTPTACity
            FROM MasterEmployee ME 
            INNER JOIN MasterOffice mo on mo.id=me.OFFICEID
            INNER JOIN MasterAddress ma on ma.TableKey=mo.id and ( ma.TableName='MasterOffice' OR  ma.TableName='MasterEmployee')
            INNER JOIN MasterCity mc on mc.id=ma.cityid
            WHERE ME.EmployeeCode = p_employeecode;

    -- Get the Allowance from MasterTA based on Basic Pay range
    SELECT CASE 
            WHEN v_IsTPTACity =0 THEN NormalCity
            WHEN v_IsTPTACity = 1 THEN TPTACity
            ELSE 0
           END
    INTO v_Allowance
    FROM MasterTA
    WHERE v_BasicPaylevelId BETWEEN PLFrom AND PLTo;

    RETURN v_Allowance;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1; -- Return -1 if employee or allowance not found
    WHEN OTHERS THEN
        RETURN -2; -- Return -2 for unexpected errors
END UDF_GetEmployeeAllowance;

/
--------------------------------------------------------
--  DDL for Function UDF_GETEMPLOYEETA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_GETEMPLOYEETA" (p_employeecode VARCHAR2)
RETURN NUMBER
IS
    v_BasicPaylevelId NUMBER;
    v_IsTPTACity NUMBER;
    v_Allowance NUMBER;
BEGIN

    -- Get Employee Level
        SELECT B.NUMID INTO v_BasicPaylevelId FROM MASTEREMPLOYEE A 
        INNER JOIN MASTERLEVEL B ON A.LEVELID=B.ID 
        WHERE EMPLOYEECODE = p_employeecode; 
    
    -- Get Employee Basic Pay and City Type
            SELECT ME.LEVELID, mc.ISTPTACITY
            INTO v_BasicPaylevelId, v_IsTPTACity
            FROM MasterEmployee ME 
            INNER JOIN MasterOffice mo on mo.id=me.OFFICEID
            INNER JOIN MasterAddress ma on ma.TableKey=mo.id and ( ma.TableName='MasterOffice' OR  ma.TableName='MasterEmployee')
            INNER JOIN MasterCity mc on mc.id=ma.cityid
            WHERE ME.EmployeeCode = p_employeecode;

    -- Get the Allowance from MasterTA based on Basic Pay range
    SELECT CASE 
            WHEN v_IsTPTACity =0 THEN NormalCity
            WHEN v_IsTPTACity = 1 THEN TPTACity
            ELSE 0
           END
    INTO v_Allowance
    FROM MasterTA
    WHERE v_BasicPaylevelId BETWEEN PLFrom AND PLTo;

    RETURN v_Allowance;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1; -- Return -1 if employee or allowance not found
    WHEN OTHERS THEN
        RETURN -2; -- Return -2 for unexpected errors
END UDF_GetEmployeeTA;

/
--------------------------------------------------------
--  DDL for Function UDF_LEAVE_SUMMARY
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_LEAVE_SUMMARY" (p_employee_Code Varchar2, p_year NUMBER,p_month Varchar2)
RETURN VARCHAR2 IS
    v_allocated_leaves NUMBER := 0;
    v_leaves_taken NUMBER := 0;
    v_TotalPresentDays NUMBER := 0;
    v_result VARCHAR2(200);
BEGIN
    -- Get the allocated leaves from Leave_Allocation table
    SELECT NVL( GetMonthDays(p_month, p_year)  , 0) AS "totalDays"
    INTO v_allocated_leaves
    FROM DUAL;

    -- Get the total leaves taken from Employee_Leave table
    SELECT NVL(SUM(LE.LEAVEDAYS), 0)
    INTO v_leaves_taken
    FROM LeaveEntry LE INNER JOIN MASTERLEAVE ML ON ML.Id=LE.DicLeaveTypeId
    WHERE EMPLOYEECODE = p_employee_Code AND MONTH =p_month AND YEAR=p_year;
    -- AND (Lower(LeaveType) =Lower('Extra Ordinary Leave') OR Lower(LeaveType) =Lower('Half Pay Leave'));
    -- Calculate remaining leaves
    v_TotalPresentDays := v_allocated_leaves - v_leaves_taken;

    -- Format the result
    v_result := v_TotalPresentDays;

    RETURN v_result;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'No leave data found for employee Code: ' || p_employee_Code;
    WHEN OTHERS THEN
        RETURN 'Error calculating leave summary: ' || SQLERRM;
END UDF_Leave_Summary;

/
--------------------------------------------------------
--  DDL for Function UDF_SPLIT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "UDF_SPLIT" (INPUT_STRING IN VARCHAR2)
RETURN SYS.ODCIVARCHAR2LIST
IS
    result_data SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(); 

    v_value VARCHAR2(100);
   v_id NUMBER := 1; 
BEGIN

    FOR i IN 1 .. REGEXP_COUNT(INPUT_STRING, '[^,]+') LOOP
        v_value := REGEXP_SUBSTR(INPUT_STRING, '[^,]+', 1, i); 


        result_data.EXTEND;  
        result_data(result_data.LAST) := v_value;  


    END LOOP;


    RETURN result_data;
END udf_split;

/
