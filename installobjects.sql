prompt Installing PLSSQL Checkstyle Framework

set serveroutput on size unlimited

define target_user = &1

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

alter session set current_schema = &&target_user;

set define off

prompt Deploying Types

--common utilities
@@core/types/VARCHAR2_TAB.tps
@@core/types/T_GEN_RESULT.tps
@@core/types/T_GEN_RESULTS.tps
@@core/types/T_OBJECTLIST.tps
@@core/types/T_OBJECTSLIST.tps

prompt Deploying Packages

@@core/UT_TEST_GEN_HELPER.pks
@@core/UT_TEST_GEN_HELPER.pkb
@@core/UT_TEST_GENERATOR.pks
@@core/UT_TEST_GENERATOR.pkb

set linesize 200
set define &
column text format a100
column error_count noprint new_value error_count
prompt Validating installation
select name, type, sequence, line, position, text, count(1) over() error_count
  from all_errors
 where owner = upper('&&target_user')
   and name IN ('UT_TEST_GEN_HELPER','UT_TEST_GENERATOR')
   -- errors only. ignore warnings
   and attribute = 'ERROR'
/

begin
  if to_number('&&error_count') > 0 then
    raise_application_error(-20000, 'Not all sources were successfully installed.');
  end if;
end;
/

exit