CREATE OR REPLACE PACKAGE UT_TEST_GEN_HELPER IS

   -- Author  : LUW07
   -- Created : 25/05/2017 16:29:02
   -- Purpose : Helper

   TYPE t_duplicatehelper IS TABLE OF VARCHAR2(32) INDEX BY VARCHAR2(32);

   TYPE t_options_rec IS RECORD(
       parsebody     NUMBER DEFAULT 0
      ,testsdisabled NUMBER DEFAULT 1);

   FUNCTION init_self RETURN t_objectlist;

   PROCEDURE append_to_clob(i_src_clob IN OUT NOCOPY CLOB
                           ,i_new_data VARCHAR2);

   FUNCTION table_to_clob(i_text_table varchar2_tab
                         ,i_delimiter  IN VARCHAR2 := chr(10)) RETURN CLOB;

   FUNCTION clob_to_table(i_clob       IN CLOB
                         ,i_max_amount IN INTEGER := 32767
                         ,i_delimiter  IN VARCHAR2 := chr(10)) RETURN varchar2_tab;

   PROCEDURE recompile_with_scope_objects(i_run_paths IN t_objectslist);

   PROCEDURE recompile_with_scope_schema(i_schema IN VARCHAR2);

   PROCEDURE print_clob_by_line(i_data IN CLOB);

   FUNCTION precheck_ut_name(i_name IN VARCHAR2) RETURN VARCHAR2;

   FUNCTION get_ut_compliant_name(i_name     IN VARCHAR2
                                 ,i_dup_name IN NUMBER DEFAULT 1) RETURN VARCHAR2;

   FUNCTION get_ut_package_specs(i_methodname IN t_gen_result) RETURN VARCHAR2;

   FUNCTION get_ut_specs_annotations(i_methodname IN t_gen_result
                                    ,i_suitepath  IN VARCHAR2 DEFAULT 'alltests')
      RETURN VARCHAR2;

   FUNCTION get_ut_package_annotations(i_methodname IN t_gen_result) RETURN VARCHAR2;

   FUNCTION get_ut_package_methods(i_methodname IN t_gen_result) RETURN VARCHAR2;

   FUNCTION get_ut_package_body(i_methodname IN t_gen_result) RETURN VARCHAR2;

   FUNCTION get_ut_body_readme RETURN VARCHAR2;
   
   FUNCTION get_ut_package_testinfo(i_methodname IN t_gen_result) RETURN VARCHAR2;

   FUNCTION get_ut_package_emptybody(i_methodname IN t_gen_result) RETURN VARCHAR2;

END UT_TEST_GEN_HELPER;
/
