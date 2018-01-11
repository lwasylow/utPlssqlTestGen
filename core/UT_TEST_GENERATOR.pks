CREATE OR REPLACE PACKAGE UT_TEST_GENERATOR AUTHID CURRENT_USER IS

/*
  Copyright 2018 Lukasz Wasylow

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
