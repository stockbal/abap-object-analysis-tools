"! <p class="shorttext synchronized" lang="en">Object does not exist error</p>
CLASS zcx_advoat_not_exists DEFINITION
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



CLASS zcx_advoat_not_exists IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous text = text ).
  ENDMETHOD.

ENDCLASS.
