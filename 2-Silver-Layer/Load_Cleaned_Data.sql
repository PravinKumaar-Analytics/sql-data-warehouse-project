/*
                                     =============================================================
                                              Silver Layer Data Load and Cleaning
									 =============================================================
Script Purpose:
    This script loads cleaned and transformed data from Bronze to Silver.
    - Handles data trimming, formatting, and mapping.
    - Fixes inconsistent values (e.g., marital status, gender, country).
    - Converts numeric dates to proper DATE format.
    - Ensures only valid records are inserted.
*/

Use Silver;
                                             -- Silver CRM Customer Info --
                                             
TRUNCATE TABLE silver.crm_cust_info;
insert into silver.crm_cust_info (
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date
)
select
    cst_id,
    cst_key,
    trim(cst_firstname),
    trim(cst_lastname),
    case
        when upper(trim(cst_marital_status)) = 's' then 'single'
        when upper(trim(cst_marital_status)) = 'm' then 'married'
        else 'n/a'
    end,
    case
        when upper(trim(cst_gndr)) = 'f' then 'female'
        when upper(trim(cst_gndr)) = 'm' then 'male'
        else 'n/a'
    end,
    cst_create_date
from bronze.crm_cust_info
where cst_id is not null
and cst_key is not null;
select*from silver.crm_cust_info;
select*from bronze.crm_cust_info;
                                             -- Silver CRM Product Info --
                                             
TRUNCATE TABLE silver.crm_prd_info;
insert into silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
select
    prd_id,
    replace(substring(prd_key,1,5),'-','_'),
    substring(prd_key,7),
    prd_nm,
    ifnull(prd_cost,0),
    case
        when upper(prd_line) = 'm' then 'mountain'
        when upper(prd_line) = 'r' then 'road'
        when upper(prd_line) = 's' then 'other sales'
        when upper(prd_line) = 't' then 'touring'
        else 'n/a'
    end,
    date(prd_start_dt),
    null
from bronze.crm_prd_info;
												-- Silver CRM Sales Details --
                                                
TRUNCATE TABLE silver.crm_sales_details;
insert into silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
select
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    case
        when sls_order_dt = 0 then null
        else str_to_date(sls_order_dt,'%Y%m%d')
    end,
    case
        when sls_ship_dt = 0 then null
        else str_to_date(sls_ship_dt,'%Y%m%d')
    end,
    case
        when sls_due_dt = 0 then null
        else str_to_date(sls_due_dt,'%Y%m%d')
    end,
    sls_quantity * abs(sls_price),
    sls_quantity,
    abs(sls_price)
from bronze.crm_sales_details
where sls_ord_num is not null;

                                                -- Silver ERP Customer --
                                                
TRUNCATE TABLE silver.erp_cust_az12;
insert into silver.erp_cust_az12 (
    cid,
    bdate,
    gen
)
select
    replace(cid,'nas',''),
    case
        when bdate > current_date then null
        else bdate
    end,
    case
        when upper(gen) in ('f','female') then 'female'
        when upper(gen) in ('m','male') then 'male'
        else 'n/a'
    end
from bronze.erp_cust_az12
where cid is not null;

                                                  -- Silver ERP Local --
                                                  
TRUNCATE TABLE silver.erp_loc_a101;
insert into silver.erp_loc_a101 (
    cid,
    cntry
)
select
    replace(cid,'-',''),
    case
        when cntry = 'de' then 'germany'
        when cntry in ('us','usa') then 'united states'
        when cntry is null or cntry = '' then 'n/a'
        else cntry
    end
from bronze.erp_loc_a101;

                                               -- Silver ERP Product Category --
                                               
TRUNCATE TABLE silver.erp_px_cat_g1v2;
truncate table silver.erp_px_cat_g1v2;

insert into silver.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance
)
select
    id,
    cat,
    subcat,
    maintenance
from bronze.erp_px_cat_g1v2
where id is not null;

                                         ----- TO CHECK ALL THE DATA IN BRONZE THAT EXIST IN SILVER -----
SELECT 
  (SELECT COUNT(*) FROM bronze.crm_cust_info)  AS bronze_cnt,
  (SELECT COUNT(*) FROM silver.crm_cust_info)  AS silver_cnt;

SELECT 
  (SELECT COUNT(*) FROM bronze.crm_prd_info)   AS bronze_cnt,
  (SELECT COUNT(*) FROM silver.crm_prd_info)   AS silver_cnt;

SELECT 
  (SELECT COUNT(*) FROM bronze.crm_sales_details) AS bronze_cnt,
  (SELECT COUNT(*) FROM silver.crm_sales_details) AS silver_cnt;

-- ERP
SELECT 
  (SELECT COUNT(*) FROM bronze.erp_loc_a101)   AS bronze_cnt,
  (SELECT COUNT(*) FROM silver.erp_loc_a101)   AS silver_cnt;

SELECT 
  (SELECT COUNT(*) FROM bronze.erp_cust_az12)  AS bronze_cnt,
  (SELECT COUNT(*) FROM silver.erp_cust_az12)  AS silver_cnt;

SELECT 
  (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2) AS bronze_cnt,
  (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2) AS silver_cnt;

                                                  ----- TO VALIDATE THE CLEAN DATA -------
			   ----- CRM -----
SELECT * FROM silver.crm_cust_info WHERE cst_id IS NULL OR cst_key IS NULL;
SELECT * FROM silver.crm_prd_info  WHERE prd_id IS NULL OR prd_key IS NULL;
SELECT * FROM silver.crm_sales_details WHERE sls_ord_num IS NULL;

	            ----- ERP ----
SELECT * FROM silver.erp_loc_a101 WHERE cid IS NULL OR cid = '';
SELECT * FROM silver.erp_cust_az12 WHERE cid IS NULL OR cid = '';
SELECT * FROM silver.erp_px_cat_g1v2 WHERE id IS NULL OR id = '';
