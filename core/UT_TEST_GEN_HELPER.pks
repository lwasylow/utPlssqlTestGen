CREATE OR REPLACE PACKAGE UT_TEST_GEN_HELPER IS

/*
 Copyright 2018 BSkyB 
   
 Licensed under the Apache License, Version 2.0 (the "License"):
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/     
   
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
