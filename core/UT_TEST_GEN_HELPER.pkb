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

CREATE OR REPLACE PACKAGE BODY UT_TEST_GEN_HELPER IS

   C_ENABLE_IDENTIFIERS  CONSTANT VARCHAR2(255) := 'ALTER SESSION SET PLSCOPE_SETTINGS=''IDENTIFIERS:ALL''';
   C_DISABLE_IDENTIFIERS CONSTANT VARCHAR2(255) := 'ALTER SESSION SET PLSCOPE_SETTINGS=''IDENTIFIERS:NONE''';
   C_UT_TEST_COMPILATION CONSTANT VARCHAR2(255) := q'[ALTER SESSION SET PLSQL_CCFLAGS = 'UNITTEST:TRUE']';
   GC_UT_PREFIX          CONSTANT VARCHAR2(3) := 'UT_';

   /*Static substitutions for diffrent types */

   --global
   g_allowed_ut_name_lenght NUMBER := 27;
   g_tab CONSTANT VARCHAR2(3) := CHR(32) || CHR(32) || CHR(32);
   g_duplicatehelper t_duplicatehelper;

   FUNCTION init_self RETURN t_objectlist IS
      l_schema   VARCHAR2(30) := sys_context('userenv', 'current_schema');
      l_object   VARCHAR2(30) := $$PLSQL_UNIT;
      l_fullname t_objectlist;
   BEGIN
      l_fullname := t_objectlist(l_object, l_schema, NULL);
      RETURN l_fullname;
   END init_self;

   PROCEDURE append_to_clob(i_src_clob IN OUT NOCOPY CLOB
                           ,i_new_data CLOB) IS
   BEGIN
      IF i_new_data IS NOT NULL AND dbms_lob.getlength(i_new_data) > 0 THEN
         IF i_src_clob IS NULL THEN
            dbms_lob.createtemporary(i_src_clob, TRUE);
         END IF;
         dbms_lob.append(i_src_clob, i_new_data);
      END IF;
   END;

   PROCEDURE append_to_clob(i_src_clob IN OUT NOCOPY CLOB
                           ,i_new_data VARCHAR2) IS
   BEGIN
      IF i_new_data IS NOT NULL THEN
         IF i_src_clob IS NULL THEN
            dbms_lob.createtemporary(i_src_clob, TRUE);
         END IF;
         dbms_lob.writeappend(i_src_clob, length(i_new_data), i_new_data);
      END IF;
   END;

   FUNCTION table_to_clob(i_text_table varchar2_tab
                         ,i_delimiter  IN VARCHAR2 := chr(10)) RETURN CLOB IS
      l_result          CLOB;
      l_text_table_rows INTEGER := coalesce(cardinality(i_text_table), 0);
   BEGIN
      FOR i IN 1 .. l_text_table_rows
      LOOP
         IF i < l_text_table_rows THEN
            append_to_clob(l_result, i_text_table(i) || i_delimiter);
         ELSE
            append_to_clob(l_result, i_text_table(i));
         END IF;
      END LOOP;
      RETURN l_result;
   END;

   FUNCTION string_to_table(a_string                 VARCHAR2
                           ,a_delimiter              VARCHAR2 := chr(10)
                           ,a_skip_leading_delimiter VARCHAR2 := 'N') RETURN varchar2_tab IS
      l_offset                 INTEGER := 1;
      l_delimiter_position     INTEGER;
      l_skip_leading_delimiter BOOLEAN := coalesce(a_skip_leading_delimiter = 'Y', FALSE);
      l_result                 varchar2_tab := varchar2_tab();
   BEGIN
      IF a_string IS NULL THEN
         RETURN l_result;
      END IF;
      IF a_delimiter IS NULL THEN
         RETURN varchar2_tab(a_string);
      END IF;
   
      LOOP
         l_delimiter_position := instr(a_string, a_delimiter, l_offset);
         IF NOT (l_delimiter_position = 1 AND l_skip_leading_delimiter) THEN
            l_result.extend;
            IF l_delimiter_position > 0 THEN
               l_result(l_result.last) := substr(a_string, l_offset,
                                                 l_delimiter_position - l_offset);
            ELSE
               l_result(l_result.last) := substr(a_string, l_offset);
            END IF;
         END IF;
         EXIT WHEN l_delimiter_position = 0;
         l_offset := l_delimiter_position + 1;
      END LOOP;
      RETURN l_result;
   END;

   PROCEDURE recompile_with_scope_schema(i_schema IN VARCHAR2) IS
   
   BEGIN
      EXECUTE IMMEDIATE C_UT_TEST_COMPILATION;
      EXECUTE IMMEDIATE C_ENABLE_IDENTIFIERS;
   
      dbms_utility.compile_schema(SCHEMA => i_schema);
   
      EXECUTE IMMEDIATE C_DISABLE_IDENTIFIERS;
   
   END recompile_with_scope_schema;

   PROCEDURE recompile_with_scope_objects(i_run_paths IN t_objectslist) IS
      l_sql VARCHAR2(4000);
   BEGIN
      EXECUTE IMMEDIATE C_UT_TEST_COMPILATION;
      EXECUTE IMMEDIATE C_ENABLE_IDENTIFIERS;
   
      FOR listofobjects IN 1 .. i_run_paths.COUNT
      LOOP
         BEGIN
            l_sql := 'ALTER ' || CASE
                        WHEN i_run_paths(listofobjects).objecttype IN ('PACKAGE BODY') THEN
                         'PACKAGE'
                        ELSE
                         i_run_paths(listofobjects).objecttype
                     END || ' ' || i_run_paths(listofobjects).objectowner || '.' || i_run_paths(listofobjects)
                    .objectname || ' COMPILE ' || CASE
                        WHEN i_run_paths(listofobjects).objecttype IN ('PACKAGE BODY') THEN
                         'BODY'
                        ELSE
                         NULL
                     END;
            EXECUTE IMMEDIATE l_sql;
         END;
      END LOOP;
   
      EXECUTE IMMEDIATE C_DISABLE_IDENTIFIERS;
   
   END recompile_with_scope_objects;

   FUNCTION clob_to_table(i_clob       IN CLOB
                         ,i_max_amount IN INTEGER := 32767
                         ,i_delimiter  IN VARCHAR2 := chr(10)) RETURN varchar2_tab IS
      l_offset                 INTEGER := 1;
      l_length                 INTEGER := dbms_lob.getlength(i_clob);
      l_amount                 INTEGER;
      l_buffer                 VARCHAR2(32767);
      l_last_line              VARCHAR2(32767);
      l_string_results         varchar2_tab;
      l_results                varchar2_tab := varchar2_tab();
      l_has_last_line          BOOLEAN;
      l_skip_leading_delimiter VARCHAR2(1) := 'N';
   BEGIN
      WHILE l_offset <= l_length
      LOOP
         l_amount := i_max_amount - coalesce(length(l_last_line), 0);
         dbms_lob.read(i_clob, l_amount, l_offset, l_buffer);
         l_offset := l_offset + l_amount;
      
         l_string_results := string_to_table(l_last_line || l_buffer, i_delimiter,
                                             l_skip_leading_delimiter);
         FOR i IN 1 .. l_string_results.count
         LOOP
            --if a split of lines was not done or not at the last line
            IF l_string_results.count = 1 OR i < l_string_results.count THEN
               l_results.extend;
               l_results(l_results.last) := l_string_results(i);
            END IF;
         END LOOP;
      
         --check if we need to append the last line to the next element
         IF l_string_results.count = 1 THEN
            l_has_last_line := FALSE;
            l_last_line     := NULL;
         ELSIF l_string_results.count > 1 THEN
            l_has_last_line := TRUE;
            l_last_line     := l_string_results(l_string_results.count);
         END IF;
      
         l_skip_leading_delimiter := 'Y';
      END LOOP;
      IF l_has_last_line THEN
         l_results.extend;
         l_results(l_results.last) := l_last_line;
      END IF;
      RETURN l_results;
   END;

   /*
   FUNCTION get_console_report(i_sourcedata IN t_scope_result_rows) RETURN CLOB IS
      l_report    CLOB;
      l_file_part VARCHAR2(32767);
   
   BEGIN
      dbms_lob.createtemporary(l_report, TRUE);
   
      IF i_sourcedata IS NOT NULL THEN
      
         FOR summary IN (SELECT COUNT(1) total
                               ,object_owner
                         FROM   TABLE(i_sourcedata)
                         GROUP  BY object_owner
                         ORDER  BY object_owner)
         LOOP
            l_file_part := 'For Schema: ' || summary.object_owner || ' there are :' ||
                           summary.total || ' checkstyle errors' || CHR(10);
         
            dbms_lob.writeappend(l_report, length(l_file_part), l_file_part);
         END LOOP;
      
         l_file_part := CHR(10) || 'Please see details:' || CHR(10);
         dbms_lob.writeappend(l_report, length(l_file_part), l_file_part);
      
         FOR data IN (SELECT *
                      FROM   TABLE(i_sourcedata)
                      ORDER  BY object_owner
                               ,object_name
                               ,object_type
                               ,line)
         LOOP
            l_file_part := 'Object Owner : ' || data.object_owner || CHR(10) ||
                           'Object Name : ' || data.object_name || CHR(10) ||
                           'Object Type : ' || data.object_type || CHR(10) ||
                           'Identifier : ' || data.identifier || CHR(10) ||
                           'Line of Code : ' || data.line || CHR(10) || 'Rule Name : ' ||
                           data.rule_name || CHR(10) || 'Rule Desciption : ' ||
                           data.rule_desc || CHR(10) || CHR(10);
         
            dbms_lob.writeappend(l_report, length(l_file_part), l_file_part);
         END LOOP;
      ELSE
         l_file_part := 'No issues have been found for given checkstyle run';
      
         dbms_lob.writeappend(l_report, length(l_file_part), l_file_part);
      
      END IF;
   
      RETURN l_report;
   END get_console_report;
   
   */

   PROCEDURE print_clob_by_line(i_data IN CLOB) IS
      l_lines varchar2_tab;
   BEGIN
      l_lines := clob_to_table(i_data);
      FOR i IN 1 .. l_lines.count
      LOOP
         dbms_output.put_line(l_lines(i));
      END LOOP;
   END print_clob_by_line;

   FUNCTION precheck_ut_name(i_name IN VARCHAR2) RETURN VARCHAR2 IS
      l_ut_name VARCHAR2(32);
      l_name    VARCHAR2(32);
   BEGIN
      IF LENGTH(i_name) > g_allowed_ut_name_lenght THEN
         l_name := SUBSTR(i_name, 1, g_allowed_ut_name_lenght);
      ELSE
         l_name := i_name;
      END IF;
   
      l_ut_name := l_name;
   
      RETURN l_ut_name;
   END precheck_ut_name;

   FUNCTION get_ut_compliant_name(i_name     IN VARCHAR2
                                 ,i_dup_name IN NUMBER DEFAULT 1) RETURN VARCHAR2 IS
      l_ut_name VARCHAR2(32);
      l_name    VARCHAR2(32);
   BEGIN
      IF LENGTH(i_name) > g_allowed_ut_name_lenght THEN
         l_name := SUBSTR(i_name, 1, g_allowed_ut_name_lenght);
      ELSE
         l_name := i_name;
      END IF;
   
      IF i_dup_name > 1 THEN
         l_name := SUBSTR(l_name, 1, 28) || TRIM(BOTH ' ' FROM TO_CHAR(i_dup_name, 'XX'));
      END IF;
   
      l_ut_name := GC_UT_PREFIX || l_name;
   
      RETURN l_ut_name;
   END;

   FUNCTION get_ut_package_specs(i_methodname IN t_gen_result) RETURN VARCHAR2 IS
      l_outputline VARCHAR2(4000);
   BEGIN
      l_outputline := CHR(10) || 'CREATE OR REPLACE PACKAGE ' ||
                      UPPER(i_methodname.test_owner) || '.' ||
                      UPPER(i_methodname.ut_method_name) || ' IS' || CHR(10) || CHR(10);
      RETURN l_outputline;
   END get_ut_package_specs;

   FUNCTION get_ut_specs_annotations(i_methodname IN t_gen_result
                                    ,i_suitepath  IN VARCHAR2 DEFAULT 'alltests')
      RETURN VARCHAR2 IS
      l_outputline VARCHAR2(4000);
   BEGIN
   
      -- %suitepath(alltests)
      -- %displayname(CBS Services API)  
      -- %suite(ut_dal_cbsserv_api)
   
      l_outputline := G_TAB || '--%suitepath(' || i_suitepath || ')' || CHR(10);
      l_outputline := l_outputline || G_TAB || '--%suite(' ||
                      lower(i_methodname.ut_method_name) || ')' || CHR(10);
      l_outputline := l_outputline || G_TAB || '--%displayname(Sample Display Name) ' ||
                      CHR(10) || CHR(10);
   
      RETURN l_outputline;
   END get_ut_specs_annotations;

   FUNCTION get_ut_package_annotations(i_methodname IN t_gen_result) RETURN VARCHAR2 IS
      l_outputline VARCHAR2(4000);
   BEGIN
      l_outputline := G_TAB || '--%test(' || lower(i_methodname.ut_method_name) || ')' ||
                      CHR(10);
      l_outputline := l_outputline || G_TAB || '--%disabled' || CHR(10);
   
      l_outputline := l_outputline || G_TAB || '--%displayname(' ||
                      lower(i_methodname.ut_method_name) || ')' || CHR(10);
   
      RETURN l_outputline;
   END get_ut_package_annotations;

   FUNCTION get_ut_package_methods(i_methodname IN t_gen_result) RETURN VARCHAR2 IS
      l_outputline VARCHAR2(4000);
   BEGIN
      l_outputline := G_TAB || 'PROCEDURE ' || lower(i_methodname.ut_method_name) || ';' ||
                      CHR(10) || CHR(10);
      RETURN l_outputline;
   END get_ut_package_methods;

   FUNCTION get_ut_package_body(i_methodname IN t_gen_result) RETURN VARCHAR2 IS
      l_outputline VARCHAR2(4000);
   BEGIN
   
      l_outputline := CHR(10) || 'CREATE OR REPLACE PACKAGE BODY ' ||
                      UPPER(i_methodname.test_owner) || '.' ||
                      UPPER(i_methodname.ut_method_name) || ' IS' || CHR(10) || CHR(10);
      RETURN l_outputline;
   END get_ut_package_body;

   FUNCTION get_ut_body_readme RETURN VARCHAR2 IS
      l_outputline VARCHAR2(4000);
   BEGIN
      l_outputline := G_TAB ||
                      '/*************************************************************' ||
                      CHR(10) || G_TAB ||
                      '******************     README     ****************************' ||
                      CHR(10) || G_TAB ||
                      '* This is a generic pacakge skeleton creaed from db metadata *' ||
                      CHR(10) || G_TAB ||
                      '* by default is in disabled stated (--%disabled)             *' ||
                      CHR(10) || G_TAB ||
                      '* to enable it just remove that annotation.                  *' ||
                      CHR(10) || G_TAB ||
                      '* This is not a full test package and dont parse a code      *' ||
                      CHR(10) || G_TAB ||
                      '*************************************************************/' ||
                      CHR(10) || CHR(10);
      RETURN l_outputline;
   END get_ut_body_readme;

   FUNCTION get_ut_package_testinfo(i_methodname IN t_gen_result) RETURN VARCHAR2 IS
      l_outputline VARCHAR2(4000);
   BEGIN
      l_outputline := G_TAB || '/*******************************************************' ||
                      CHR(10) || G_TAB || '   TEST: ' || lower(i_methodname.methodname) ||
                      CHR(10) || G_TAB ||
                      '   SCENARIOS                                            ' ||
                      CHR(10) || G_TAB || '   1) Sample Desciption' || CHR(10) || G_TAB ||
                      '*******************************************************/' ||
                      CHR(10) || CHR(10);
      RETURN l_outputline;
   
   END get_ut_package_testinfo;

   FUNCTION get_ut_package_emptybody(i_methodname IN t_gen_result) RETURN VARCHAR2 IS
      l_outputline VARCHAR2(4000);
   BEGIN
      l_outputline := G_TAB || 'PROCEDURE ' || lower(i_methodname.ut_method_name) ||
                      ' IS' || CHR(10) || G_TAB || 'BEGIN' || CHR(10) || G_TAB || G_TAB ||
                      'NULL;' || CHR(10) || G_TAB || 'END ' ||
                      lower(i_methodname.ut_method_name) || ';' || CHR(10) || CHR(10);
      RETURN l_outputline;
   END get_ut_package_emptybody;

END UT_TEST_GEN_HELPER;
/
