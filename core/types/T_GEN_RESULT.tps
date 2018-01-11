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
