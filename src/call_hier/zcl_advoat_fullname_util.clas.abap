CLASS zcl_advoat_fullname_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Get ref/tag stack from full ref name</p>
      get_parts
        IMPORTING
          full_name     TYPE string
        RETURNING
          VALUE(result) TYPE zif_advoat_ty_calh=>ty_fullname_parts,
      "! <p class="shorttext synchronized" lang="en">Return object with info of fullname</p>
      get_info_obj
        IMPORTING
          full_name     TYPE string
        RETURNING
          VALUE(result) TYPE REF TO if_ris_abap_fullname.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_fullname_util IMPLEMENTATION.

  METHOD get_parts.
    DATA: tokens TYPE string_table.

    SPLIT full_name AT '\' INTO TABLE tokens.

    LOOP AT tokens INTO DATA(token) WHERE table_line IS NOT INITIAL.
      DATA(type) = token(2).
      result = VALUE #( BASE result ( name = token+3
                                      tag = token(2) ) ).
    ENDLOOP.

  ENDMETHOD.


  METHOD get_info_obj.
    result = NEW cl_ris_abap_fullname( iv_abap_fullname = full_name ).
  ENDMETHOD.

ENDCLASS.
