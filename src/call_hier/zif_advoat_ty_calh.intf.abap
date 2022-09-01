"! <p class="shorttext synchronized" lang="en">Types for Call Hierarchy</p>
INTERFACE zif_advoat_ty_calh
  PUBLIC .

  TYPES:
    ty_visibility  TYPE c LENGTH 1,
    ty_class_level TYPE c LENGTH 1,

    BEGIN OF ty_call_position,
      line   TYPE i,
      column TYPE i,
    END OF ty_call_position,
    ty_call_positions TYPE STANDARD TABLE OF ty_call_position WITH EMPTY KEY,
    BEGIN OF ty_compilation_unit,
      legacy_type           TYPE seu_stype,
      tag                   TYPE scr_tag,
      object_name           TYPE ris_parameter,
      encl_object_name      TYPE ris_parameter,
      encl_object_type      TYPE trobjtype,
      encl_obj_display_name TYPE ris_parameter,
      full_name             TYPE string,
      description           TYPE string,
      visibility            TYPE ty_visibility,
      BEGIN OF method_props,
        is_final       TYPE abap_bool,
        is_abstract    TYPE abap_bool,
        is_redefined   TYPE abap_bool,
        is_handler     TYPE abap_bool,
        is_constructor TYPE abap_bool,
        level          TYPE ty_class_level,
      END OF method_props,
      include               TYPE progname,
      main_program          TYPE progname,
      call_positions        TYPE ty_call_positions,
    END OF ty_compilation_unit.
ENDINTERFACE.
