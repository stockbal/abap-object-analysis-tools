"! <p class="shorttext synchronized" lang="en">Types for Call Hierarchy</p>
INTERFACE zif_advoat_ty_calh
  PUBLIC .

  TYPES:
    BEGIN OF ty_source_position,
      line   TYPE i,
      column TYPE i,
    END OF ty_source_position,

    "! Source information of compilation unit
    BEGIN OF ty_cu_src_info,
      main_prog TYPE progname,
      include   TYPE progname,
      start_pos TYPE zif_advoat_ty_calh=>ty_source_position,
      end_pos   TYPE zif_advoat_ty_calh=>ty_source_position,
    END OF ty_cu_src_info,

    BEGIN OF ty_ris_data_request,
      "! Original RIS data request
      orig_request      TYPE ris_s_adt_data_request,
      uri               TYPE string,
      source_pos_of_uri TYPE ty_source_position,
      is_uri_in_ccimp   TYPE abap_bool,
    END OF ty_ris_data_request,

    BEGIN OF ty_fullname_part,
      tag  TYPE scr_tag,
      name TYPE string,
    END OF ty_fullname_part,

    ty_fullname_parts TYPE STANDARD TABLE OF ty_fullname_part WITH EMPTY KEY,

    ty_call_positions TYPE STANDARD TABLE OF ty_source_position WITH EMPTY KEY,

    BEGIN OF ty_method_properties,
      is_final       TYPE abap_bool,
      is_abstract    TYPE abap_bool,
      is_alias       TYPE abap_bool,
      is_redefined   TYPE abap_bool,
      is_handler     TYPE abap_bool,
      is_constructor TYPE abap_bool,
      is_static      TYPE abap_bool,
      visibility     TYPE zif_advoat_ty_global=>ty_visibility,
    END OF ty_method_properties,

    BEGIN OF ty_compilation_unit,
      legacy_type           TYPE seu_stype,
      adt_type              TYPE string,
      tag                   TYPE scr_tag,
      object_name           TYPE ris_parameter,
      encl_object_name      TYPE ris_parameter,
      encl_object_type      TYPE trobjtype,
      encl_obj_display_name TYPE ris_parameter,
      source_pos_start      TYPE ty_source_position,
      source_pos_end        TYPE ty_source_position,
      full_name             TYPE string,
      full_name_from_parser TYPE string,
      description           TYPE string,
      method_props          TYPE ty_method_properties,
      include               TYPE progname,
      parent_main_program   TYPE progname,
      main_program          TYPE progname,
      call_positions        TYPE ty_call_positions,
    END OF ty_compilation_unit.
ENDINTERFACE.
