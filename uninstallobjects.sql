prompt Installing PLSSQL Checkstyle Framework

set serveroutput on size unlimited

define target_user = &1

alter session set current_schema = &&target_user;

set define off

prompt Deploying Types

DROP PACKAGE UT_TEST_GENERATOR;
DROP PACKAGE UT_TEST_GEN_HELPER;

DROP TYPE T_GEN_RESULTS;
DROP TYPE T_GEN_RESULT;
DROP TYPE T_OBJECTSLIST;
DROP TYPE T_OBJECTLIST;

exit