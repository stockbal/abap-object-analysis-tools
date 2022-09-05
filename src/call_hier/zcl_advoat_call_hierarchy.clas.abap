"! <p class="shorttext synchronized" lang="en">Call hierarchy for method/form/function</p>
CLASS zcl_advoat_call_hierarchy DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS:
      get_call_hierarchy_srv
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_call_hierarchy_srv,
      "! <p class="shorttext synchronized" lang="en">Retrieves compilation unit at URI</p>
      get_comp_unit_from_uri
        IMPORTING
          uri           TYPE string
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_compilation_unit.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA:
      hierarchy_srv TYPE REF TO zif_advoat_call_hierarchy_srv.

    CLASS-METHODS:
      map_uri_to_data_request
        IMPORTING
          uri           TYPE string
        RETURNING
          VALUE(result) TYPE ris_s_adt_data_request
        RAISING
          cx_ris_exception,

      is_class_local_impl
        IMPORTING
          uri           TYPE string
        RETURNING
          VALUE(result) TYPE abap_bool.
ENDCLASS.



CLASS zcl_advoat_call_hierarchy IMPLEMENTATION.

  METHOD get_comp_unit_from_uri.
    TRY.
        DATA(data_request) = map_uri_to_data_request( uri ).

        result = zcl_advoat_comp_unit_factory=>get_instance( )->create_comp_unit_from_ext(
          data_request = VALUE #(
            orig_request      = data_request
            uri               = uri
            is_uri_in_ccimp   = is_class_local_impl( uri )
            source_pos_of_uri = zcl_advoat_adt_uri_util=>get_uri_source_start_pos( uri ) ) ).
      CATCH cx_ris_exception zcx_advoat_exception.
        "handle exception
    ENDTRY.
  ENDMETHOD.


  METHOD get_call_hierarchy_srv.
    IF hierarchy_srv IS INITIAL.
      hierarchy_srv = NEW zcl_advoat_call_hierarchy_srv(
        comp_unit_factory = zcl_advoat_comp_unit_factory=>get_instance( ) ).
    ENDIF.

    result = hierarchy_srv.
  ENDMETHOD.


  METHOD map_uri_to_data_request.

    cl_ris_adt_position_mapping=>map_uri_to_ris_data_request(
      EXPORTING
        iv_uri          = uri
        it_source_code  = VALUE #( )
      IMPORTING
        es_data_request = result ).

  ENDMETHOD.

  METHOD is_class_local_impl.
    result = xsdbool( matches( val = uri regex = `^/sap/bc/adt/oo/classes/[\w%]+/includes/implementation.*` ) ).
  ENDMETHOD.

ENDCLASS.
