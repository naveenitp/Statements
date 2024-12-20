SELECT COALESCE(CONCAT(CONVERT(c.first_name USING utf8mb4),' ',coalesce(CONVERT(c.last_name USING utf8mb4),'')),'N/A')
customer_name,
    s.serial_number,
    CASE bs.use_mac WHEN '1' THEN s.mac_address ELSE COALESCE(epl.vc_number, s.vc_number) END AS vc_number,
    'Package Activation' AS action_type,
    ep.pname AS package,
    CASE
        WHEN e.users_type IN ('DEALER', 'ADMIN', 'EMPLOYEE', 'SERVICE', 'TEAMLEAD') THEN COALESCE(CONCAT(CONVERT(e.first_name USING utf8mb4), ' ', CONVERT(e.last_name USING utf8mb4)), 'N/A')
        ELSE COALESCE(CONCAT(CONVERT(e.business_name USING utf8mb4), ' (', e.dist_subdist_lcocode, ')'), 'N/A')
    END AS action_done_by,
    cl.activation_date AS action_done_on,
    bs.display_name AS cas,    
    em.model_name AS model
FROM
    eb_stock_cas_services cl
    LEFT JOIN eb_pairing_logs epl ON epl.stock_id=cl.stock_id AND epl.pairing_log_id=(SELECT MAX(pairing_log_id) FROM eb_pairing_logs WHERE created_on <= cl.created_on AND status=1 AND stock_id=cl.stock_id)
LEFT JOIN
    employee e ON cl.created_by = e.employee_id AND e.dealer_id = 1
INNER JOIN
    eb_stock s ON cl.stock_id = s.stock_id
INNER JOIN
    eb_products ep ON ep.product_id = cl.product_id
INNER JOIN
    eb_models em ON s.model_number = em.model_id
INNER JOIN
backend_setups bs ON bs.backend_setup_id = s.backend_setup_id AND bs.dealer_id=1
LEFT JOIN
customer_device cd ON cd.box_number=s.serial_number AND cd.dealer_id=1  AND (cl.activation_date >= COALESCE(cd.created_on,'0000-00-00 00:00:00') AND cl.activation_date < COALESCE(cd.device_closed_on,'3000-12-31 11:59:59'))
LEFT JOIN
customer c ON c.customer_id=cd.customer_id AND c.dealer_id=1
WHERE
    s.dealer_id = 1  
    AND (cl.activation_date >= '2024-06-01 00:00:00'
    AND cl.activation_date <= '2024-06-30 23:59:59') INTO OUTFILE '/tmp/temp_act_logs_20240601_20240630.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "temp_act_logs generated";

CREATE TEMPORARY TABLE IF NOT EXISTS temp_act_logs_table_20240601_20240630(
customer_name varchar(200),
serial_number varchar(200),
vc_number varchar(200),
action_type varchar(200),
package varchar(200),
action_done_by varchar(200),
action_done_on datetime DEFAULT NULL,
cas varchar(100),
model varchar(100)
);

LOAD DATA INFILE '/tmp/temp_act_logs_20240601_20240630.csv' INTO TABLE temp_act_logs_table_20240601_20240630 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

SELECT COALESCE(CONCAT(CONVERT(c.first_name USING utf8mb4),' ',coalesce(CONVERT(c.last_name USING utf8mb4),'')),'N/A')
customer_name,s.serial_number,CASE bs.use_mac WHEN '1' THEN s.mac_address ELSE COALESCE(epl.vc_number, s.vc_number) END AS vc_number,'Package Deactivation' AS action_type,ep.pname AS package,
CASE WHEN e.users_type IN ('DEALER', 'ADMIN', 'EMPLOYEE', 'SERVICE', 'TEAMLEAD') THEN COALESCE(CONCAT(CONVERT(e.first_name USING utf8mb4), ' ', CONVERT(e.last_name USING utf8mb4)), 'N/A')
        ELSE COALESCE(CONCAT(CONVERT(e.business_name USING utf8mb4), ' (', e.dist_subdist_lcocode, ')'), 'N/A')
    END AS action_done_by,
cl.deactivation_date AS action_done_on,bs.display_name AS cas,em.model_name as model FROM
eb_stock_cas_services cl
LEFT JOIN eb_pairing_logs epl ON epl.stock_id=cl.stock_id AND epl.pairing_log_id=(SELECT MAX(pairing_log_id) FROM eb_pairing_logs WHERE created_on <= cl.created_on AND status=1 AND stock_id=cl.stock_id)
LEFT JOIN employee e ON cl.modify_by = e.employee_id AND e.dealer_id=1
INNER JOIN employee emp ON cl.reseller_id = emp.employee_id
INNER JOIN eb_stock s ON cl.stock_id=s.stock_id AND s.dealer_id=1
INNER JOIN eb_products ep ON ep.product_id = cl.product_id
INNER JOIN eb_models em ON s.model_number = em.model_id
LEFT JOIN customer_device cd ON cd.box_number=s.serial_number AND cd.dealer_id=1  AND (cl.activation_date >= COALESCE(cd.created_on,'0000-00-00 00:00:00') AND cl.activation_date < COALESCE(cd.device_closed_on,'3000-12-31 11:59:59'))
LEFT JOIN customer c ON c.customer_id=cd.customer_id AND c.dealer_id=1
INNER JOIN backend_setups bs ON bs.backend_setup_id = s.backend_setup_id AND bs.dealer_id=1
WHERE s.dealer_id=1 AND (cl.deactivation_date >= '2024-06-01 00:00:00'
    AND cl.deactivation_date <= '2024-06-30 23:59:59') INTO OUTFILE '/tmp/temp_deact_logs_data_test_20240601_20240630.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "deact_logs generated";

CREATE TEMPORARY TABLE IF NOT EXISTS temp_deact_logs_table_20240601_20240630(
customer_name varchar(200),
serial_number varchar(200),
vc_number varchar(200),
action_type varchar(200),
package varchar(200),
action_done_by varchar(200),
action_done_on datetime DEFAULT NULL,
cas varchar(100),
model varchar(100)
);

LOAD DATA INFILE '/tmp/temp_deact_logs_data_test_20240601_20240630.csv' INTO TABLE temp_deact_logs_table_20240601_20240630 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

SELECT COALESCE(CONCAT(CONVERT(c.first_name USING utf8mb4),' ',coalesce(CONVERT(c.last_name USING utf8mb4),'')),'N/A')
customer_name,
s.serial_number,
CASE bs.use_mac WHEN '1' THEN s.mac_address ELSE COALESCE(epl.vc_number, s.vc_number) END AS vc_number,
CASE cms.mac_id WHEN 'Global' THEN 'Global Messaging' ELSE 'Messaging' END AS action_type,
cm.content as package,
CASE
        WHEN e.users_type IN ('DEALER', 'ADMIN', 'EMPLOYEE', 'SERVICE', 'TEAMLEAD') THEN COALESCE(CONCAT(CONVERT(e.first_name USING utf8mb4), ' ', CONVERT(e.last_name USING utf8mb4)), 'N/A')
        ELSE COALESCE(CONCAT(CONVERT(e.business_name USING utf8mb4), ' (', e.dist_subdist_lcocode, ')'), 'N/A')
    END AS action_done_by,
cms.sent_on AS action_done_on,bs.display_name AS cas,em.model_name as model FROM eb_cas_msg_sent_to cms
INNER JOIN eb_cas_messages cm ON cm.message_id=cms.msg_id
INNER JOIN employee e ON e.employee_id= cm.sent_by AND e.dealer_id=1
LEFT JOIN eb_stock s ON s.serial_number = cms.mac_id AND s.dealer_id=1
LEFT JOIN eb_pairing_logs epl ON epl.stock_id=s.stock_id AND epl.pairing_log_id=(SELECT MAX(pairing_log_id) FROM eb_pairing_logs WHERE created_on <= cms.sent_on AND status=1 AND stock_id=s.stock_id) 
LEFT JOIN eb_models em ON s.model_number = em.model_id LEFT JOIN customer_device cd ON cd.box_number=s.serial_number AND cd.dealer_id=1  AND (cms.sent_on >= COALESCE(cd.created_on,'0000-00-00 00:00:00') AND cms.sent_on <= COALESCE(cd.device_closed_on,'3000-12-31 11:59:59')) 
LEFT JOIN backend_setups bs ON bs.backend_setup_id = cm.backend_setup_id AND bs.dealer_id=1 
LEFT JOIN customer c ON c.customer_id=cd.customer_id AND c.dealer_id=1 
WHERE e.dealer_id=1 AND (cms.sent_on >= '2024-06-01 00:00:00' AND cms.sent_on <= '2024-06-30 23:59:59') 
INTO OUTFILE '/tmp/temp_message_logs_data_test_20240601_20240630.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "message_logs generated";

CREATE TEMPORARY TABLE IF NOT EXISTS temp_message_logs_table_20240601_20240630(
customer_name varchar(200),
serial_number varchar(200),
vc_number varchar(200),
action_type varchar(200),
package varchar(200),
action_done_by varchar(200),
action_done_on datetime DEFAULT NULL,
cas varchar(100),
model varchar(100)
);

LOAD DATA INFILE '/tmp/temp_message_logs_data_test_20240601_20240630.csv' INTO TABLE temp_message_logs_table_20240601_20240630 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

SELECT COALESCE(CONCAT(CONVERT(c.first_name USING utf8mb4),' ',coalesce(CONVERT(c.last_name USING utf8mb4),'')),'N/A')
customer_name,
COALESCE(s.serial_number,'N/A') serial_number,
CASE bs.use_mac WHEN '1' THEN s.mac_address ELSE COALESCE(epl.vc_number, s.vc_number) END AS vc_number,
CASE cf.stock_id WHEN '-1' THEN 'Global FingerPrint' ELSE 'FingerPrint' END AS action_type,
'NA' as package,
CASE WHEN e.users_type IN ('DEALER', 'ADMIN', 'EMPLOYEE', 'SERVICE', 'TEAMLEAD') THEN COALESCE(CONCAT(CONVERT(e.first_name USING utf8mb4), ' ', CONVERT(e.last_name USING utf8mb4)), 'N/A')
        ELSE COALESCE(CONCAT(CONVERT(e.business_name USING utf8mb4), ' (', e.dist_subdist_lcocode, ')'), 'N/A')
    END AS action_done_by,
    cf.created_on AS action_done_on,bs.display_name AS cas,
em.model_name as model FROM eb_cas_fingerprint_logs cf 
LEFT JOIN eb_pairing_logs epl ON epl.stock_id=cf.stock_id AND epl.pairing_log_id=(SELECT MAX(pairing_log_id) FROM eb_pairing_logs WHERE created_on <= cf.created_on AND status=1 AND stock_id=cf.stock_id) 
INNER JOIN employee e ON cf.created_by = e.employee_id AND e.dealer_id=1 
LEFT JOIN eb_stock s ON s.stock_id = cf.stock_id AND s.dealer_id=1 
LEFT JOIN eb_models em ON s.model_number = em.model_id 
LEFT JOIN customer c ON c.customer_id=cf.customer_id AND c.dealer_id=1 
LEFT JOIN eb_channels ch ON cf.channel_id = ch.channel_id 
LEFT JOIN backend_setups bs ON bs.backend_setup_id = cf.backend_setup_id AND bs.dealer_id=1 
LEFT JOIN customer_device cd ON cd.customer_id = c.customer_id AND cd.dealer_id=1 AND (cf.activated_date >= COALESCE(cd.created_on,'0000-00-00 00:00:00') 
AND cf.activated_date <= COALESCE(cd.device_closed_on,'3000-12-31 11:59:59')) WHERE cf.activated_date<>'0000-00-00 00:00:00' 
AND cf.dealer_id=1 AND (cf.activated_date >= '2024-06-01 00:00:00' AND cf.activated_date <= '2024-06-30 23:59:59') INTO OUTFILE '/tmp/temp_fingerprint_logs_data_test_20240601_20240630.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "fingerprint_logs generated";


CREATE TEMPORARY TABLE IF NOT EXISTS temp_fingerprint_logs_table_20240601_20240630(
customer_name varchar(200),
serial_number varchar(200),
vc_number varchar(200),
action_type varchar(200),
package varchar(200),
action_done_by varchar(200),
action_done_on datetime DEFAULT NULL,
cas varchar(100),
model varchar(100)
);

LOAD DATA INFILE '/tmp/temp_fingerprint_logs_data_test_20240601_20240630.csv' INTO TABLE temp_fingerprint_logs_table_20240601_20240630 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

SELECT COALESCE(CONCAT(CONVERT(c.first_name USING utf8mb4),' ',coalesce(CONVERT(c.last_name USING utf8mb4),'')),'N/A')
customer_name,
COALESCE(s.serial_number,'N/A') serial_number,
pl.vc_number vc_number,
CASE pl.status WHEN '0' THEN 'UnPaired' WHEN '1' THEN 'Paired' END AS action_type,
'NA' as package,
CASE WHEN e.users_type IN ('DEALER', 'ADMIN', 'EMPLOYEE', 'SERVICE', 'TEAMLEAD') THEN COALESCE(CONCAT(CONVERT(e.first_name USING utf8mb4), ' ', CONVERT(e.last_name USING utf8mb4)), 'N/A')
        ELSE COALESCE(CONCAT(CONVERT(e.business_name USING utf8mb4), ' (', e.dist_subdist_lcocode, ')'), 'N/A')
    END AS action_done_by,
pl.created_on AS action_done_on,
bs.display_name AS cas,
em.model_name as model FROM eb_pairing_logs pl 
INNER JOIN employee e ON pl.created_by = e.employee_id AND e.dealer_id=1 
LEFT JOIN eb_stock s ON s.stock_id = pl.stock_id AND s.dealer_id=1 
LEFT JOIN eb_models em ON s.model_number = em.model_id 
LEFT JOIN customer_device cd ON cd.box_number = s.serial_number AND cd.dealer_id=1  AND (pl.created_on >= COALESCE(cd.created_on,'0000-00-00 00:00:00') AND pl.created_on <= COALESCE(cd.device_closed_on,'3000-12-31 11:59:59')) 
LEFT JOIN customer c ON c.customer_id=cd.customer_id AND c.dealer_id=1 
LEFT JOIN backend_setups bs ON bs.backend_setup_id = s.backend_setup_id AND bs.dealer_id=1 
WHERE pl.dealer_id=1  AND (pl.created_on >= '2024-06-01 00:00:00' AND pl.created_on <= '2024-06-30 23:59:59') INTO OUTFILE '/tmp/temp_pairing_logs_data_test_20240601_20240630.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
'; 


select "pairing_logs generated";

CREATE TEMPORARY TABLE IF NOT EXISTS temp_pairing_logs_table_20240601_20240630(
customer_name varchar(200),
serial_number varchar(200),
vc_number varchar(200),
action_type varchar(200),
package varchar(200),
action_done_by varchar(200),
action_done_on datetime DEFAULT NULL,
cas varchar(100),
model varchar(100)
);

LOAD DATA INFILE '/tmp/temp_pairing_logs_data_test_20240601_20240630.csv' INTO TABLE temp_pairing_logs_table_20240601_20240630 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

SELECT COALESCE(CONCAT(CONVERT(c.first_name USING utf8mb4),' ',coalesce(CONVERT(c.last_name USING utf8mb4),'')),'N/A')
customer_name,
 COALESCE(s.serial_number,'N/A') serial_number, 
 CASE bs.use_mac WHEN '1' THEN s.mac_address ELSE COALESCE(epl.vc_number, s.vc_number) END AS vc_number,
'Reactivation'  AS action_type,
ep.pname as package,
CASE WHEN e.users_type IN ('DEALER', 'ADMIN', 'EMPLOYEE', 'SERVICE', 'TEAMLEAD') THEN COALESCE(CONCAT(CONVERT(e.first_name USING utf8mb4), ' ', CONVERT(e.last_name USING utf8mb4)), 'N/A')
        ELSE COALESCE(CONCAT(CONVERT(e.business_name USING utf8mb4), ' (', e.dist_subdist_lcocode, ')'), 'N/A')
    END AS action_done_by,
    cl.date_time_stamp AS action_done_on,
    bs.display_name AS cas,em.model_name as model FROM  eb_cas_inventory_logs cl 
    LEFT JOIN eb_pairing_logs epl ON epl.stock_id=cl.stock_id AND epl.pairing_log_id=(SELECT MAX(pairing_log_id) FROM eb_pairing_logs WHERE created_on <= cl.date_time_stamp AND status=1 AND stock_id=cl.stock_id) 
    INNER JOIN employee e ON cl.created_by = e.employee_id AND e.dealer_id=1 
    LEFT JOIN eb_products ep ON ep.product_id IN(cl.product_ids) 
    LEFT JOIN eb_stock s ON s.stock_id = cl.stock_id AND s.dealer_id=1 
    LEFT JOIN eb_models em ON s.model_number = em.model_id 
    LEFT JOIN customer_device cd ON cd.box_number = s.serial_number AND cd.dealer_id=1 AND (cl.date_time_stamp >= COALESCE(cd.created_on,'0000-00-00 00:00:00') AND cl.date_time_stamp <= COALESCE(cd.device_closed_on,'3000-12-31 11:59:59')) LEFT JOIN customer c ON c.customer_id=cd.customer_id AND c.dealer_id=1 
    LEFT JOIN backend_setups bs ON bs.backend_setup_id = s.backend_setup_id AND bs.dealer_id=1 WHERE cl.act_type='R' and cl.dealer_id=1 AND (cl.date_time_stamp >= '2024-06-01 00:00:00' AND cl.date_time_stamp <= '2024-06-30 23:59:59') INTO OUTFILE '/tmp/temp_react_logs_data_test_20240601_20240630.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
'; 


select "react_logs_data generated";

CREATE TEMPORARY TABLE IF NOT EXISTS temp_react_logs_table_20240601_20240630(
customer_name varchar(200),
serial_number varchar(200),
vc_number varchar(200),
action_type varchar(200),
package varchar(200),
action_done_by varchar(200),
action_done_on datetime DEFAULT NULL,
cas varchar(100),
model varchar(100)
);

LOAD DATA INFILE '/tmp/temp_react_logs_data_test_20240601_20240630.csv' INTO TABLE temp_react_logs_table_20240601_20240630 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

SELECT COALESCE(CONCAT(CONVERT(c.first_name USING utf8mb4),' ',coalesce(CONVERT(c.last_name USING utf8mb4),'')),'N/A')
customer_name,
s.serial_number,
CASE bs.use_mac WHEN '1' THEN s.mac_address ELSE COALESCE(s.vc_number,'NA') END AS vc_number,
'STB black listing' AS action_type,
s.product_name AS package,
CASE WHEN e.users_type IN ('DEALER', 'ADMIN', 'EMPLOYEE', 'SERVICE', 'TEAMLEAD') THEN COALESCE(CONCAT(CONVERT(e.first_name USING utf8mb4), ' ', CONVERT(e.last_name USING utf8mb4)), 'N/A')
        ELSE COALESCE(CONCAT(CONVERT(e.business_name USING utf8mb4), ' (', e.dist_subdist_lcocode, ')'), 'N/A')
    END AS action_done_by,
    s.modified_date AS action_done_on,
    bs.display_name AS cas,
    em.model_name as model 
 FROM eb_stock s 
 LEFT JOIN employee e ON s.modified_by = e.employee_id AND e.dealer_id=1 
 LEFT JOIN customer_device cd ON cd.box_number = s.serial_number AND customer_device_id=(select max(customer_device_id) from customer_device where box_number = s.serial_number) 
 LEFT JOIN eb_models em ON s.model_number = em.model_id 
 LEFT JOIN backend_setups bs ON bs.backend_setup_id = s.backend_setup_id AND bs.dealer_id=1 
 LEFT JOIN customer c ON c.customer_id = cd.customer_id WHERE s.status=3 AND s.defective_stock=0 AND s.dealer_id=1 AND (s.modified_date >= '2024-06-01 00:00:00' AND s.modified_date <= '2024-06-30 23:59:59') INTO OUTFILE '/tmp/temp_blacklist_logs_data_test_20240601_20240630.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
'; 

select "blacklist_logs generated";

CREATE TEMPORARY TABLE IF NOT EXISTS temp_blacklist_logs_table_20240601_20240630(
customer_name varchar(200),
serial_number varchar(200),
vc_number varchar(200),
action_type varchar(200),
package varchar(200),
action_done_by varchar(200),
action_done_on datetime DEFAULT NULL,
cas varchar(100),
model varchar(100)
);

LOAD DATA INFILE '/tmp/temp_blacklist_logs_data_test_20240601_20240630.csv' INTO TABLE temp_blacklist_logs_table_20240601_20240630 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';


CREATE TEMPORARY TABLE temp_stb_logs_export_20240601_20240630 (
  id int(11) NOT NULL AUTO_INCREMENT,	
  Customer_Name varchar(200) DEFAULT NULL,
  Serial_Number varchar(201) DEFAULT NULL,
  VC_Number varchar(201) DEFAULT NULL,
  Action_Type varchar(200) DEFAULT NULL,
  Package varchar(200) DEFAULT NULL,
  Action_Done_By varchar(200) DEFAULT NULL,
  Action_Done_On datetime DEFAULT NULL,
  CAS varchar(100) DEFAULT NULL,
  Model varchar(100) DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;


SELECT x.customer_name AS Customer_Name,
CONCAT('\'', '', x.serial_number) AS Serial_Number,
CONCAT('\'', '', x.vc_number) AS VC_Number,
x.action_type AS Action_Type,
x.package AS Package,
x.action_done_by AS Action_Done_By,
x.action_done_on AS Action_Done_On,
x.cas AS CAS,
x.model AS Model 
FROM (
SELECT * FROM temp_act_logs_table_20240601_20240630
UNION ALL
SELECT * FROM temp_deact_logs_table_20240601_20240630
UNION ALL 
SELECT * FROM temp_message_logs_table_20240601_20240630
UNION ALL 
SELECT * FROM temp_fingerprint_logs_table_20240601_20240630
UNION ALL 
SELECT * FROM temp_pairing_logs_table_20240601_20240630 
UNION ALL 
SELECT * FROM temp_react_logs_table_20240601_20240630 
UNION ALL 
SELECT * FROM temp_blacklist_logs_table_20240601_20240630
) x 
ORDER BY x.Action_Done_On DESC
INTO OUTFILE '/tmp/temp_stb_logs_export_20240601_20240630.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

load data local infile '/tmp/temp_stb_logs_export_20240601_20240630.csv' into table temp_stb_logs_export_20240601_20240630 fields terminated by ',' enclosed by '"' lines terminated by '\n' 
(Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model);


select "temp_stb_logs generated";

select count(*) from temp_stb_logs_export_20240601_20240630;

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 0,200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306001.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_20230601 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 200000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306002.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';
select "stb_logs_20230602 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 400000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306003.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306003 generated";


SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 600000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306004.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306004 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 800000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306005.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306005 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 1000000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306006.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306006 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 1200000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306007.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306007 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 1400000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306008.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306008 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 1600000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306009.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306009 generated";


SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 1800000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306010.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306010 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 2000000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306011.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306011 generated";


SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 2200000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306012.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306012 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 2400000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306013.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306013 generated";


SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 2600000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306014.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306014 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 2800000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306015.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306015 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 3000000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306016.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';



select "stb_logs_202306016 generated";


SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 3200000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306017.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306017 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 3400000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306018.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306018 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 3600000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306019.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306019 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 3800000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306020.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306020 generated";

SELECT 'Customer_Name','Serial_Number','VC_Number','Action_Type','Package','Action_Done_By','Action_Done_On','CAS','Model' UNION ALL
SELECT Customer_Name,Serial_Number,VC_Number,Action_Type,Package,Action_Done_By,Action_Done_On,CAS,Model
FROM temp_stb_logs_export_20240601_20240630
LIMIT 4000000, 200000
INTO OUTFILE '/tmp/stb_logs/july2024/stb_logs_202306021.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '
';

select "stb_logs_202306021 generated";