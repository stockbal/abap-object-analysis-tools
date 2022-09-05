"! <p class="shorttext synchronized" lang="en">Wrapper around ABAP Parser</p>
CLASS zcl_advoat_abap_parser DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      constructor,
      "! <p class="shorttext synchronized" lang="en">Retrieve element information for full name</p>
      calculate_element_info
        IMPORTING
          full_name     TYPE string
        RETURNING
          VALUE(result) TYPE REF TO cl_abap_cc_prog_object,
      "! <p class="shorttext synchronized" lang="en">Fills method information from cc element</p>
      fill_method_information
        IMPORTING
          element_info TYPE REF TO cl_abap_cc_prog_object
        returning
          value(result) type zif_advoat_ty_calh=>ty_method_properties,
      "! <p class="shorttext synchronized" lang="en">Retrieve the enclosing object type</p>
      get_encl_method_type
        IMPORTING
          full_name     TYPE scr_ref-full_name
        RETURNING
          VALUE(result) TYPE trobjtype..
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA:
      parser TYPE REF TO cl_abap_parser.
ENDCLASS.



CLASS zcl_advoat_abap_parser IMPLEMENTATION.

  METHOD constructor.
    parser = NEW #( ).
  ENDMETHOD.


  METHOD calculate_element_info.
    result = parser->calculate_element_info_by_name( fullname = full_name ).
  ENDMETHOD.


  METHOD fill_method_information.
    DATA(method_info) = CAST cl_abap_cc_method( element_info ).

    result = VALUE #(
      is_abstract    = xsdbool( method_info->is_abstract = sccmp_true )
      is_alias       = xsdbool( method_info->role = sccmp_role_methodalias )
      is_constructor = xsdbool( method_info->is_constructor = sccmp_true )
      is_final       = xsdbool( method_info->is_final = sccmp_true )
      is_handler     = xsdbool( method_info->is_handler = sccmp_true )
      is_redefined   = xsdbool( method_info->is_redefined = sccmp_true )
      is_static      = xsdbool( method_info->member_kind = sccmp_member_class )
      visibility = SWITCH #( method_info->visibility
        WHEN sccmp_visibility_private   THEN zif_advoat_c_method_visibility=>private
        WHEN sccmp_visibility_protected THEN zif_advoat_c_method_visibility=>protected
        WHEN sccmp_visibility_public    THEN zif_advoat_c_method_visibility=>public ) ).

  ENDMETHOD.


  METHOD get_encl_method_type.
    DATA(tag_index) = find( val = full_name sub = '\ME' ).
    DATA(full_type_name) = full_name(tag_index).

    DATA(type_elem_info) = calculate_element_info( full_type_name ).
    IF type_elem_info IS NOT INITIAL.
      result = COND #(
        WHEN type_elem_info->role = sccmp_role_classtype THEN 'CLAS'
        WHEN type_elem_info->role = sccmp_role_intftype THEN 'INTF' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
