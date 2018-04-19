--Apache Hive Essentials
--Chapter 5 Code - Hive data manupulation

--Create partition table DDL.
--Load local data to table
LOAD DATA LOCAL INPATH '/home/dayongd/Downloads/employee_hr.txt' OVERWRITE INTO TABLE employee_hr;

--Load local data to partition table
LOAD DATA LOCAL INPATH '/home/dayongd/Downloads/employee.txt'
OVERWRITE INTO TABLE employee_partitioned
PARTITION (year=2018, month=12);

--Load HDFS data to table using default system path
LOAD DATA INPATH '/tmp/hivedemo/data/employee.txt' 
OVERWRITE INTO TABLE employee;

--Load HDFS data to table with full URI
LOAD DATA INPATH 
'hdfs://[dfs_hostname]:9000/tmp/hivedemo/data/employee.txt' 
OVERWRITE INTO TABLE employee;

--Data Exchange - INSERT
--Check the target table
SELECT name, work_place, sex_age FROM employee;              

--Populate data from SELECT
INSERT INTO TABLE employee
SELECT * FROM ctas_employee;

--Verify the data loaded
SELECT name, work_place, sex_age FROM employee;    

--Insert specified columns
CREATE TABLE emp_simple( -- Create a test table only has primary types
name string,
work_place string
);
INSERT INTO TABLE emp_simple(name) -- Specify which columns to insert
SELECT name FROM employee WHERE name = 'Will';

--Insert values
INSERT INTO TABLE emp_simple VALUES ('Michael', 'Toronto'),('Lucy', 'Montreal');
SELECT * FROM emp_simple;

--INSERT from CTE
WITH a as (SELECT * FROM ctas_employee )
FROM a
INSERT OVERWRITE TABLE employee
SELECT *;

--Multiple INSERTS by only scanning the source table once
FROM ctas_employee
INSERT OVERWRITE TABLE employee
SELECT *
INSERT OVERWRITE TABLE employee_internal
SELECT * 
INSERT OVERWRITE TABLE employee_partitioned partition(year=2018, month=9)
SELECT * 
;

--Dynamic partition is not enabled by default. We need to set following to make it work.
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nostrict;

--Dynamic partition insert
INSERT INTO TABLE employee_partitioned PARTITION(year, month)
SELECT name, array('Toronto') as work_place, 
named_struct("sex","Male","age",30) as sex_age, 
map("Python",90) as skills_score,
map("R&D",array('Developer')) as depart_title, 
year(start_date) as year, month(start_date) as month
FROM employee_hr eh
WHERE eh.employee_id = 102;

--Verify the inserted row
SELECT name,depart_title,year,month FROM employee_partitioned
WHERE name = 'Steven';

--Insert to local files with default row separators
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/output1' 
SELECT * FROM employee;

--Insert to local files with specified row separators
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/output2' 
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
SELECT * FROM employee;

--Multiple INSERT
FROM employee
INSERT OVERWRITE DIRECTORY '/tmp/output3'
SELECT *
INSERT OVERWRITE DIRECTORY '/tmp/output4'
SELECT * ;

--Export data and metadata of table
EXPORT TABLE employee TO '/tmp/output5';

--dfs -ls -R /tmp/output5/

--Import table with the same name
IMPORT FROM '/tmp/output5';              

--Import as new table
IMPORT TABLE empolyee_imported FROM '/tmp/output5';

--Import as external table 
IMPORT EXTERNAL TABLE empolyee_imported_external 
FROM '/tmp/output5'
LOCATION '/tmp/output6' ; --Note, LOCATION property is optional.

--Export and import to partitions
EXPORT TABLE employee_partitioned partition 
(year=2018, month=12) TO '/tmp/output7';

IMPORT TABLE employee_partitioned_imported 
FROM '/tmp/output7';                     

--ORDER, SORT
SELECT name FROM employee ORDER BY name DESC;
SELECT * FROM emp_simple ORDER BY work_place NULL LAST;

--Use more than 1 reducer
SET mapred.reduce.tasks = 2;

SELECT name FROM employee SORT BY name DESC;   

--Use only 1 reducer
SET mapred.reduce.tasks = 1; 

SELECT name FROM employee SORT BY name DESC;   

--Distribute by
SELECT name, employee_id 
FROM employee_hr DISTRIBUTE BY employee_id ; 

--Used with SORT BY
SELECT name, start_date FROM employee_hr DISTRIBUTE BY start_date SORT BY name;

--Cluster by
SELECT name, employee_id FROM employee_hr CLUSTER BY name ;   

--Complex datatype function
SELECT 
size(work_place) AS array_size, 
size(skills_score) AS map_size, 
size(depart_title) AS complex_size, 
size(depart_title["Product"]) AS nest_size 
FROM employee;

SELECT size(null), size(array(null)), size(array());

--Arrary functions
SELECT array_contains(work_place, 'Toronto') AS is_Toronto, sort_array(work_place) AS sorted_array FROM employee;

--Date and time functions
SELECT to_date(from_unixtime(unix_timestamp())) AS currentdate;

--To compare the difference of two date.
SELECT (unix_timestamp('2018-01-21 18:00:00') - unix_timestamp('2018-01-10 11:00:00'))/60/60/24 AS daydiff;

--Get the file name form a Linux path
SELECT reverse(split(reverse('/home/user/employee.txt'),'/')[0]) AS linux_file_name;  

--collect set or list
SELECT 
collect_set(sex_age.sex) AS sex_set,
collect_list(sex_age.sex) AS sex_list
FROM employee;

--Transactions
--Below configuration parameters must be set appropriately to turn on transaction support in Hive.
SET hive.support.concurrency = true;
SET hive.enforce.bucketing = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.txn.manager = org.apache.hadoop.hive.ql.lockmgr.DbTxnManager;
SET hive.compactor.initiator.on = true;
SET hive.compactor.worker.threads = 1;

--Show avaliable transactions
SHOW TRANSACTIONS;
