![](https://img.shields.io/badge/ABAP-v7.40sp08+-orange)
# abap-object-analysis-tools
Advanced Object Analysis tools

## Package overview
- **/src**  
  Miscellaneous utils, helpers, exceptions
- **/src/wb_obj**
  Classes concerning Workbench objects
- **/src/oea**
  Contains repository objects for Object Environment Analysis  
- **/src/parl**
  Contains repository objects for parallel processing
  
  Important Objects in package  
  Object Name               | Purpose
  --------------------------|------------------------------------
  ZCL_ADVOAT_OEA_ANALYZER   | Central class which handles object environment analysis. Can be created via ZCL_ADVOAT_OEA_FACTORY=>CREATE_ANALYZER

## Installation

Install this repository using [abapGit](https://github.com/abapGit/abapGit#abapgit).
