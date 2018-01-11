# Overview
Basic package to generate test scenarios based on schema or package name

# Usage
Call UT_TEST_GENERATOR.RUN with a name of schema or schema and objectand owner of the test packages.

# Privs
Owner of the packge has to be able to recompile schema so alter any procedure and also exec on dbms_recompile.
##select from dba_identifiers
##alter any procedure
##exec on dbms_recompile

