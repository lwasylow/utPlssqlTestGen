CREATE OR REPLACE PACKAGE BODY UT_TEST_GENERATOR IS

   g_test_owner     VARCHAR2(32);
   g_current_schema VARCHAR2(30) := sys_context('userenv', 'current_schema');

   FUNCTION init_self RETURN t_objectlist IS
      l_schema   VARCHAR2(30) := sys_context('userenv', 'current_schema');
      l_object   VARCHAR2(30) := $$PLSQL_UNIT;
      l_fullname t_objectlist;
   BEGIN
      l_fullname := t_objectlist(l_object, l_schema, NULL);
      RETURN l_fullname;
   END init_self;

   PROCEDURE set_options(i_testowner IN VARCHAR2) IS
   BEGIN
      g_test_owner := NVL(i_testowner, sys_context('userenv', 'current_schema'));
   END set_options;

   PROCEDURE set_module(i_modulename IN VARCHAR2 DEFAULT 'PLSCOPE') IS
   
   BEGIN
      dbms_application_info.set_module(module_name => i_modulename, action_name => NULL);
   END set_module;

   FUNCTION exclude_framework_objects RETURN t_objectslist IS
      l_excluded_objects t_objectslist := t_objectslist();
   BEGIN
      dbms_application_info.set_action(action_name => 'Exclude Errors');
   
      l_excluded_objects.extend;
      l_excluded_objects(l_excluded_objects.LAST) := init_self;
   
      RETURN l_excluded_objects;
   END;
   --Return list of all objects to be tested
   FUNCTION get_object_list(i_schemas IN varchar2_tab
                           ,i_objects IN varchar2_tab) RETURN t_objectslist IS
      l_objectlist    t_objectslist;
      l_excluded_list t_objectslist := exclude_framework_objects;
   
      CURSOR c_schemas_object IS
         SELECT t_objectlist(o.object_name, o.owner, o.object_type)
         FROM   all_objects o
         WHERE  o.owner IN (SELECT *
                            FROM   TABLE(i_schemas))
         AND    o.object_name IN (SELECT *
                                  FROM   TABLE(i_objects))
         AND    o.object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE')
         AND    o.generated <> 'Y'
         AND    NOT EXISTS
          (SELECT 1
                 FROM   TABLE(l_excluded_list) t
                 WHERE  o.object_name = NVL(t.objectname, o.object_name)
                 AND    o.owner = NVL(t.objectowner, o.owner)
                 AND    o.object_type = NVL(t.objecttype, o.object_type))
         ORDER  BY o.owner
                  ,o.object_name
                  ,CASE
                      WHEN o.object_type IN ('PACKAGE') THEN
                       1
                      ELSE
                       2
                   END;
   
      CURSOR c_schemas IS
         SELECT t_objectlist(o.object_name, o.owner, o.object_type)
         FROM   all_objects o
         WHERE  o.owner IN (SELECT *
                            FROM   TABLE(i_schemas))
         AND    o.object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE')
         AND    o.generated <> 'Y'
         AND    NOT EXISTS
          (SELECT 1
                 FROM   TABLE(l_excluded_list) t
                 WHERE  o.object_name = NVL(t.objectname, o.object_name)
                 AND    o.owner = NVL(t.objectowner, o.owner)
                 AND    o.object_type = NVL(t.objecttype, o.object_type))
         ORDER  BY o.owner
                  ,o.object_name
                  ,CASE
                      WHEN o.object_type IN ('PACKAGE') THEN
                       1
                      ELSE
                       2
                   END;
   BEGIN
      dbms_application_info.set_action(action_name => 'Gather Object List');
   
      IF i_objects.COUNT = 0 THEN
         OPEN c_schemas;
         FETCH c_schemas BULK COLLECT
            INTO l_objectlist;
         CLOSE c_schemas;
      ELSE
         OPEN c_schemas_object;
         FETCH c_schemas_object BULK COLLECT
            INTO l_objectlist;
         CLOSE c_schemas_object;
      END IF;
   
      RETURN l_objectlist;
   END get_object_list;

   PROCEDURE print_report(i_report_data IN CLOB) AS
   
   BEGIN
      ut_test_gen_helper.print_clob_by_line(i_data => i_report_data);
   END print_report;

   FUNCTION investigate_objects(i_path IN t_objectslist) RETURN t_gen_results IS
   
      CURSOR c_specs_lookup IS
         SELECT t_gen_result(object_name, owner, object_type, NAME, TYPE, usage_id,
                             usage_context_id, g_test_owner,
                             ut_test_gen_helper.get_ut_compliant_name(i_name => NAME,
                                                                       i_dup_name => dup_ut_name))
         FROM   (SELECT i.object_name
                       ,i.owner
                       ,i.object_type
                       ,i.name
                       ,i.type
                       ,i.usage_id
                       ,i.usage_context_id
                       ,ROW_NUMBER() OVER(PARTITION BY object_name, owner, object_type, ut_test_gen_helper.precheck_ut_name(i_name => i.name) ORDER BY i.name) dup_ut_name
                 FROM   dba_identifiers i
                       ,TABLE(i_path) p
                 WHERE  i.owner = p.objectowner
                 AND    object_name = p.objectname
                 AND    object_type = p.objecttype
                 AND    usage = 'DECLARATION'
                 AND    i.type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE')
                 ORDER  BY i.owner
                          ,i.object_name
                          ,CASE
                              WHEN TYPE = 'PACKAGE' THEN
                               '1'
                              ELSE
                               '2'
                           END);
   
      l_resulttab t_gen_results;
   
   BEGIN
      OPEN c_specs_lookup;
      FETCH c_specs_lookup BULK COLLECT
         INTO l_resulttab;
      CLOSE c_specs_lookup;
   
      RETURN l_resulttab;
   END investigate_objects;

   PROCEDURE build_specs(i_objectdetail IN t_gen_result
                        ,o_spec         OUT NOCOPY CLOB) IS
      l_line VARCHAR2(4000);
   BEGIN
   
      IF (i_objectdetail.TYPE = 'PACKAGE' AND i_objectdetail.objecttype = 'PACKAGE') THEN
         l_line := ut_test_gen_helper.get_ut_package_specs(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         l_line := ut_test_gen_helper.get_ut_specs_annotations(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
      
      ELSIF (i_objectdetail.TYPE = 'FUNCTION' AND i_objectdetail.objecttype = 'FUNCTION') OR
            (i_objectdetail.TYPE = 'PROCEDURE' AND
            i_objectdetail.objecttype = 'PROCEDURE') THEN
         l_line := ut_test_gen_helper.get_ut_package_specs(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         l_line := ut_test_gen_helper.get_ut_specs_annotations(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         --Add annotations
         l_line := ut_test_gen_helper.get_ut_package_annotations(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         --Add defnition
         l_line := ut_test_gen_helper.get_ut_package_methods(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
      ELSE
         --Add annotations
         l_line := ut_test_gen_helper.get_ut_package_annotations(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         --Add defnition
         l_line := ut_test_gen_helper.get_ut_package_methods(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
      END IF;
   END build_specs;

   PROCEDURE build_body(i_objectdetail IN t_gen_result
                       ,o_spec         OUT NOCOPY CLOB) IS
      l_line VARCHAR2(4000);
   BEGIN
   
      IF i_objectdetail.TYPE = 'PACKAGE' THEN
         l_line := ut_test_gen_helper.get_ut_package_body(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         l_line := ut_test_gen_helper.get_ut_body_readme;
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
      ELSIF i_objectdetail.TYPE = 'FUNCTION' AND i_objectdetail.objecttype = 'FUNCTION' THEN
         l_line := ut_test_gen_helper.get_ut_package_body(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         l_line := ut_test_gen_helper.get_ut_body_readme;
         --Add Info table
         l_line := ut_test_gen_helper.get_ut_package_testinfo(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         --Add defnition
         l_line := ut_test_gen_helper.get_ut_package_emptybody(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
      ELSIF i_objectdetail.TYPE = 'PROCEDURE' AND i_objectdetail.objecttype = 'PROCEDURE' THEN
         l_line := ut_test_gen_helper.get_ut_package_body(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         l_line := ut_test_gen_helper.get_ut_body_readme;
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         --Add Info table
         l_line := ut_test_gen_helper.get_ut_package_testinfo(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         --Add defnition
         l_line := ut_test_gen_helper.get_ut_package_emptybody(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
      ELSE
         --Add Info table
         l_line := ut_test_gen_helper.get_ut_package_testinfo(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
         --Add defnition
         l_line := ut_test_gen_helper.get_ut_package_emptybody(i_methodname => i_objectdetail);
         ut_test_gen_helper.append_to_clob(i_src_clob => o_spec, i_new_data => l_line);
      END IF;
   END build_body;

   PROCEDURE build_package(i_object  IN t_objectlist
                          ,i_methods IN t_gen_results
                          ,o_results OUT NOCOPY CLOB) IS
      l_tmppackage CLOB;
      l_package    CLOB;
      CURSOR c_methods IS
         SELECT t_gen_result(objectname => m.objectname, objectowner => m.objectowner,
                             objecttype => m.objecttype, methodname => m.methodname,
                             TYPE => m.type, usage_id => m.usage_id,
                             usage_context_id => m.usage_context_id, g_test_owner,
                             ut_method_name => m.ut_method_name) methodnames
         FROM   TABLE(i_methods) m
         WHERE  m.objectname = i_object.objectname
         AND    m.objectowner = i_object.objectowner
         AND    m.objecttype = i_object.objecttype;
   
      l_duplicate_helper ut_test_gen_helper.t_duplicatehelper;
   BEGIN
   
      --For each object generate package specs
      FOR objects IN c_methods
      LOOP
      
         build_specs(i_objectdetail => objects.methodnames, o_spec => l_tmppackage);
         ut_test_gen_helper.append_to_clob(i_src_clob => l_package,
                                           i_new_data => l_tmppackage);
      END LOOP;
      --Close Specs
      ut_test_gen_helper.append_to_clob(i_src_clob => l_package,
                                        i_new_data => 'END;' || CHR(10) || '/' || CHR(10));
   
      FOR objects IN c_methods
      LOOP
         build_body(i_objectdetail => objects.methodnames, o_spec => l_tmppackage);
         ut_test_gen_helper.append_to_clob(i_src_clob => l_package,
                                           i_new_data => l_tmppackage);
      END LOOP;
      --Close Specs
      ut_test_gen_helper.append_to_clob(i_src_clob => l_package,
                                        i_new_data => 'END;' || CHR(10) || '/' || CHR(10));
   
      o_results := l_package;
   
   END;

   PROCEDURE generate_tests(i_schemas   IN varchar2_tab
                           ,i_objects   IN varchar2_tab
                           ,i_testowner IN VARCHAR2 DEFAULT NULL
                           ,o_results   OUT NOCOPY CLOB) IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   
      l_path            t_objectslist := get_object_list(i_schemas => i_schemas,
                                                         i_objects => i_objects);
      l_schema_path     t_objectslist := t_objectslist();
      l_identifiedtests t_gen_results := t_gen_results();
      l_tmpresults      CLOB;
      l_outresults      CLOB;
   BEGIN
      set_options(i_testowner => i_testowner);
      dbms_application_info.set_action(action_name => 'Recompile Scope');
   
      IF i_objects.COUNT = 0 THEN
         --Workaround issue when schema compiled is schema where package is being executed
         --that creates a lock
         FOR listofschemas IN 1 .. i_schemas.COUNT
         LOOP
            IF i_schemas(listofschemas) = g_current_schema THEN
               l_schema_path := get_object_list(i_schemas => varchar2_tab(g_current_schema),
                                                i_objects => i_objects);
               ut_test_gen_helper.recompile_with_scope_objects(i_run_paths => l_schema_path);
            ELSE
               ut_test_gen_helper.recompile_with_scope_schema(i_schema => i_schemas(listofschemas));
            END IF;
         END LOOP;
      ELSE
         ut_test_gen_helper.recompile_with_scope_objects(i_run_paths => l_path);
      END IF;
   
      --Investiage DBA IDENTIFIERS to pull some basic info to build   
      l_identifiedtests := investigate_objects(i_path => l_path);
   
      --Generate a package details passing options
      FOR objects IN 1 .. l_path.COUNT
      LOOP
         build_package(i_object => l_path(objects), i_methods => l_identifiedtests,
                       o_results => l_tmpresults);
         ut_test_gen_helper.append_to_clob(i_src_clob => l_outresults,
                                           i_new_data => l_tmpresults);
      END LOOP;
   
      l_path.DELETE;
   
      o_results := l_outresults;
   
   END generate_tests;

   PROCEDURE generate_with_print(i_schemas   IN varchar2_tab
                                ,i_objects   IN varchar2_tab
                                ,i_testowner IN VARCHAR2 DEFAULT NULL) IS
      l_result_set CLOB;
   BEGIN
      generate_tests(i_schemas => i_schemas, i_objects => i_objects,
                     o_results => l_result_set, i_testowner => i_testowner);
      print_report(i_report_data => l_result_set);
   
   END generate_with_print;

   PROCEDURE run(i_schema    IN VARCHAR2 DEFAULT NULL
                ,i_object    IN VARCHAR2
                ,i_testowner IN VARCHAR2 DEFAULT NULL) IS
   
      l_schema  varchar2_tab := varchar2_tab(coalesce(i_schema, g_current_schema));
      l_objects varchar2_tab := varchar2_tab(i_object);
   BEGIN
      set_module;
      generate_with_print(i_schemas => l_schema, i_objects => l_objects,
                          i_testowner => i_testowner);
   END run;

   FUNCTION run(i_schema    IN VARCHAR2 DEFAULT NULL
               ,i_object    IN VARCHAR2
               ,i_testowner IN VARCHAR2 DEFAULT NULL) RETURN varchar2_tab
      PIPELINED IS
      l_schema     varchar2_tab := varchar2_tab(coalesce(i_schema, g_current_schema));
      l_objects    varchar2_tab := varchar2_tab(i_object);
      l_result_set CLOB;
      l_returntype varchar2_tab;
   BEGIN
      generate_tests(i_schemas => l_schema, i_objects => l_objects,
                     o_results => l_result_set, i_testowner => i_testowner);
   
      l_returntype := ut_test_gen_helper.clob_to_table(i_clob => l_result_set);
   
      FOR codelines IN 1 .. l_returntype.COUNT
      LOOP
         PIPE ROW(l_returntype(codelines));
      END LOOP;
   END run;

   PROCEDURE run(i_schema    IN VARCHAR2 DEFAULT NULL
                ,i_testowner IN VARCHAR2 DEFAULT NULL) IS
   
      l_schema  varchar2_tab := varchar2_tab(coalesce(i_schema, g_current_schema));
      l_objects varchar2_tab := varchar2_tab();
   BEGIN
      set_module;
      generate_with_print(i_schemas => l_schema, i_objects => l_objects,
                          i_testowner => i_testowner);
   END run;

   FUNCTION run(i_schema    IN VARCHAR2 DEFAULT NULL
               ,i_testowner IN VARCHAR2 DEFAULT NULL) RETURN varchar2_tab
      PIPELINED IS
      l_schema     varchar2_tab := varchar2_tab(coalesce(i_schema, g_current_schema));
      l_objects    varchar2_tab := varchar2_tab();
      l_result_set CLOB;
      l_returntype varchar2_tab;
   BEGIN
      generate_tests(i_schemas => l_schema, i_objects => l_objects,
                     o_results => l_result_set, i_testowner => i_testowner);
   
      l_returntype := ut_test_gen_helper.clob_to_table(i_clob => l_result_set);
   
      FOR codelines IN 1 .. l_returntype.COUNT
      LOOP
         PIPE ROW(l_returntype(codelines));
      END LOOP;
   END run;

END UT_TEST_GENERATOR;
/
