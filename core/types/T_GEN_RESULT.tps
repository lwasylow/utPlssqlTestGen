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

CREATE OR REPLACE TYPE T_GEN_RESULT AS OBJECT
(
   objectname   VARCHAR2(128),
   objectowner VARCHAR2(128),
   objecttype VARCHAR2(128),
   methodname VARCHAR2(32),
   type       VARCHAR2(255),
   usage_id   NUMBER,
   usage_context_id NUMBER,
   test_owner VARCHAR2(32),
   ut_method_name VARCHAR2(30)
)
/
