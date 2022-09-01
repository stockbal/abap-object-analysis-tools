"! <p class="shorttext synchronized" lang="en">Call hierarchy for method/form/function</p>
CLASS zcl_advoat_call_tree DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Retrieves compilation unit at URI</p>
      get_compilation_unit
        IMPORTING
          uri           TYPE string
          source_code   TYPE string_table OPTIONAL
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_compilation_unit.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_call_tree IMPLEMENTATION.

  METHOD get_compilation_unit.
    TRY.
        cl_ris_adt_position_mapping=>map_uri_to_ris_data_request(
          EXPORTING
            iv_uri          = uri
            it_source_code  = source_code
          IMPORTING
            es_data_request = DATA(data_request) ).

        DATA(unit_data) = CORRESPONDING zif_advoat_ty_calh=>ty_compilation_unit( data_request ).

        unit_data-encl_obj_display_name = unit_data-encl_object_name.

        result = NEW zcl_advoat_compilation_unit( data = unit_data ).
      CATCH cx_ris_exception zcx_advoat_exception.
        "handle exception
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
