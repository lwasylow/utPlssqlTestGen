CREATE OR REPLACE PACKAGE UT_TEST_GENERATOR IS

   -- Author  : LUW07
   -- Created : 25/05/2017 16:29:02
   -- Purpose : Static code analysis

   TYPE t_reporter_rec IS RECORD(
       reporter_name VARCHAR2(10) DEFAULT 'CONSOLE');

   TYPE t_reporter_tab IS TABLE OF t_reporter_rec;

   PROCEDURE run(i_schema    IN VARCHAR2 DEFAULT NULL
                ,i_object    IN VARCHAR2
                ,i_testowner IN VARCHAR2 DEFAULT NULL);

   FUNCTION run(i_schema    IN VARCHAR2 DEFAULT NULL
               ,i_object    IN VARCHAR2
               ,i_testowner IN VARCHAR2 DEFAULT NULL) RETURN varchar2_tab
      PIPELINED;

   PROCEDURE run(i_schema    IN VARCHAR2 DEFAULT NULL
                ,i_testowner IN VARCHAR2 DEFAULT NULL);

   FUNCTION run(i_schema    IN VARCHAR2 DEFAULT NULL
               ,i_testowner IN VARCHAR2 DEFAULT NULL) RETURN varchar2_tab
      PIPELINED;

END UT_TEST_GENERATOR;
/
