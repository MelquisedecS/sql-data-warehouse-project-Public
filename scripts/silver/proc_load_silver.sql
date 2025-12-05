/*
=======================================================================
Stored Procedure. Load Silver Layer ( Bronze --> Siver)
=======================================================================
Scrip Purpose:
  This stored procedure performs RETL ( Extract, Transform, Load) 
  process to populate the 'siver' schema .
Actions Performed:
    -Truncates Silver Tables.
    -Inserts transformed and cleansed data from Bronze into  Silver 
      Tables.
Parameters:
  None.
  This stored procedure does not accept any parametrs or  return any values

Usage Example:
  CALL silver.load_silver()
=======================================================================
*/

CALL silver.load_silver();

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '=======================================';
    RAISE NOTICE 'Starting Silver Layer Load';
    RAISE NOTICE '=======================================';

    ------------------------------------------------------------
    -- SILVER.CRM_CUST_INFO
    ------------------------------------------------------------
    start_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> Truncating Table : silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;

    RAISE NOTICE '>> Inserting into : silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info(
        cst_id, cst_key, cst_firstname, cst_lastname, cst_material_status, cst_gndr, cst_create_data
    )
    SELECT 
        cst_id, cst_key,
        TRIM(cst_firstname), TRIM(cst_lastname),
        CASE WHEN UPPER(TRIM(cst_material_status))='S' THEN 'Single'
             WHEN UPPER(TRIM(cst_material_status))='M' THEN 'Married'
             ELSE 'n/a' END,
        CASE WHEN UPPER(TRIM(cst_gndr))='F' THEN 'Female'
             WHEN UPPER(TRIM(cst_gndr))='M' THEN 'Male'
             ELSE 'n/a' END,
        cst_create_data
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_data DESC) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE flag_last = 1;

    end_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> CRM_CUST_INFO Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>>-------------';

    ------------------------------------------------------------
    -- SILVER.CRM_PRD_INFO
    ------------------------------------------------------------
    start_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> Truncating Table : silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;

    RAISE NOTICE '>> Inserting into : silver.crm_prd_info';
    INSERT INTO silver.crm_prd_info(
        prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
        SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key,
        prd_nm,
        COALESCE(prd_cost,0),
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Moutain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END,
        CAST(prd_start_dt AS DATE),
        CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day' AS DATE)
    FROM bronze.crm_prd_info;

    end_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> CRM_PRD_INFO Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>>-------------';

    ------------------------------------------------------------
    -- SILVER.CRM_SALES_DETAILS
    ------------------------------------------------------------
    start_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> Truncating Table : silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;

    RAISE NOTICE '>> Inserting into : silver.crm_sales_details';
    INSERT INTO silver.crm_sales_details(
        sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price
    )
    SELECT
        sls_ord_num, sls_prd_key, sls_cust_id,
        CASE WHEN sls_order_dt<=0 OR LENGTH(CAST(sls_order_dt AS TEXT))!=8 THEN NULL
             ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) END,
        CASE WHEN sls_ship_dt<=0 OR LENGTH(CAST(sls_ship_dt AS TEXT))!=8 THEN NULL
             ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) END,
        CASE WHEN sls_due_dt<=0 OR LENGTH(CAST(sls_due_dt AS TEXT))!=8 THEN NULL
             ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) END,
        CASE WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales!=sls_quantity*ABS(sls_price)
             THEN sls_quantity*ABS(sls_price)
             ELSE sls_sales END,
        sls_quantity,
        CASE WHEN sls_price IS NULL OR sls_price<=0
             THEN sls_sales/NULLIF(sls_quantity,0)
             ELSE sls_price END
    FROM bronze.crm_sales_details;

    end_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> CRM_SALES_DETAILS Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>>-------------';

    ------------------------------------------------------------
    -- SILVER.ERP_CUST_AZ12
    ------------------------------------------------------------
    start_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> Truncating Table : silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;

    RAISE NOTICE '>> Inserting into : silver.erp_cust_az12';
    INSERT INTO silver.erp_cust_az12(cid,bdate,gen)
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4) ELSE cid END,
        CASE WHEN bdate>CURRENT_DATE THEN NULL ELSE bdate END,
        CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
             WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
             ELSE 'n/a' END
    FROM bronze.erp_cust_az12;

    end_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> ERP_CUST_AZ12 Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>>-------------';

    ------------------------------------------------------------
    -- SILVER.ERP_LOC_A101
    ------------------------------------------------------------
    start_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> Truncating Table : silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;

    RAISE NOTICE '>> Inserting into : silver.erp_loc_a101';
    INSERT INTO silver.erp_loc_a101(cid,cntry)
    SELECT
        REPLACE(cid,'','') AS cid,
        CASE WHEN TRIM(cntry)='DE' THEN 'Germany'
             WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
             WHEN TRIM(cntry)='' OR cntry IS NULL THEN 'n/a'
             ELSE TRIM(cntry) END
    FROM bronze.erp_loc_a101;

    end_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> ERP_LOC_A101 Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>>-------------';

    ------------------------------------------------------------
    -- SILVER.ERP_PX_CAT_G1V2
    ------------------------------------------------------------
    start_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> Truncating Table : silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    RAISE NOTICE '>> Inserting into : silver.erp_px_cat_g1v2';
    INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
    SELECT id, cat, subcat, maintenance
    FROM bronze.erp_px_cat_g1v2;

    end_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '>> ERP_PX_CAT_G1V2 Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '=======================================';
    RAISE NOTICE 'Silver Layer Load Completed';
    RAISE NOTICE '=======================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '=======================================';
        RAISE NOTICE 'ERROR OCCURRED DURING SILVER LOAD';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE 'SQLSTATE: %', SQLSTATE;
        RAISE NOTICE 'PLEASE LOAD MANUALLY';
        RAISE NOTICE '=======================================';
END;
$$;
