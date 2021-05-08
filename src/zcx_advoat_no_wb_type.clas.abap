"! <p class="shorttext synchronized" lang="en">No workbench object type determined</p>
CLASS zcx_advoat_no_wb_type DEFINITION
  PUBLIC
  INHERITING FROM zcx_advoat_exception
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS:
      "! <p class="shorttext synchronized" lang="en">CONSTRUCTOR</p>
      constructor
        IMPORTING
          previous LIKE previous OPTIONAL
          text     TYPE string OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcx_advoat_no_wb_type IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor(
      previous = previous
      text     = text ).
  ENDMETHOD.

ENDCLASS.
