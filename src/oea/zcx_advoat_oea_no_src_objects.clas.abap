"! <p class="shorttext synchronized" lang="en">No Source objects for analysis</p>
CLASS zcx_advoat_oea_no_src_objects DEFINITION
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



CLASS zcx_advoat_oea_no_src_objects IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor(
      previous = previous
      text     = text ).
  ENDMETHOD.

ENDCLASS.
