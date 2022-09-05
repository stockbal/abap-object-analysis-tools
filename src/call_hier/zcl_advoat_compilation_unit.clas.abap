"! <p class="shorttext synchronized" lang="en">Compilation unit</p>
CLASS zcl_advoat_compilation_unit DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_advoat_comp_unit_factory.

  PUBLIC SECTION.
    INTERFACES zif_advoat_compilation_unit.

    METHODS:
      constructor
        IMPORTING
          hierarchy_service TYPE REF TO zif_advoat_call_hierarchy_srv
          data              TYPE zif_advoat_ty_calh=>ty_compilation_unit
        RAISING
          zcx_advoat_exception,

      set_hierarchy_possible
        IMPORTING
          value TYPE abap_bool.
  PROTECTED SECTION.
  PRIVATE SECTION.
    ALIASES:
      unit_info FOR zif_advoat_compilation_unit~unit_info.

    TYPES:
      BEGIN OF ty_comp_unit_by_line,
        line TYPE i,
        ref  TYPE REF TO zif_advoat_compilation_unit,
      END OF ty_comp_unit_by_line,

      BEGIN OF ty_ref_entry,
        type TYPE scr_tag,
        name TYPE string,
      END OF ty_ref_entry,

      ty_ref_stack TYPE STANDARD TABLE OF ty_ref_entry WITH EMPTY KEY.

    DATA:
      hierarchy_service          TYPE REF TO zif_advoat_call_hierarchy_srv,

      is_hierarchy_possible      TYPE abap_bool,
      is_called_units_determined TYPE abap_bool,
      called_units               TYPE zif_advoat_compilation_unit=>ty_ref_tab.
ENDCLASS.



CLASS zcl_advoat_compilation_unit IMPLEMENTATION.

  METHOD constructor.
    unit_info = data.
    me->hierarchy_service = hierarchy_service.
    is_hierarchy_possible = abap_true.
  ENDMETHOD.


  METHOD set_hierarchy_possible.
    is_hierarchy_possible = value.
  ENDMETHOD.

  METHOD zif_advoat_compilation_unit~get_called_units.
    IF is_called_units_determined = abap_false.
      IF is_hierarchy_possible = abap_true.
        called_units = hierarchy_service->determine_called_units( me ).
      ENDIF.
      is_called_units_determined = abap_true.
    ENDIF.

    result = called_units.
  ENDMETHOD.

  METHOD zif_advoat_compilation_unit~get_call_position_uri.
**********************************************************************
    " 1) direct jump to definition of form

**cl_wb_request=>create_from_encl_name(
**  EXPORTING
**    p_object_type      = 'PU'
**    p_encl_object_name = 'SAPLSEUA' " include name
**    p_object_name      = 'INFOSYSTEM_OBJECT_PROGRAM_GET' " Form name
**    p_operation        = 'DISPLAY'
**  RECEIVING
**    p_wb_request       = wb_request
**  EXCEPTIONS
**    OTHERS             = 1
**).

**********************************************************************


    IF unit_info-include IS NOT INITIAL.
      DATA(adt_tools_factory) = cl_adt_tools_core_factory=>get_instance( ).
      DATA(uri_mapper) = adt_tools_factory->get_uri_mapper( ).

      IF unit_info-parent_main_program IS INITIAL AND
          unit_info-main_program IS NOT INITIAL AND
          unit_info-source_pos_start IS NOT INITIAL.

        DATA(line) = unit_info-source_pos_start-line.
        DATA(col) = unit_info-source_pos_start-column.
        DATA(prog) = unit_info-main_program.
      ELSEIF unit_info-parent_main_program IS NOT INITIAL AND
           unit_info-call_positions IS NOT INITIAL.
        line = unit_info-call_positions[ 1 ]-line.
        col = unit_info-call_positions[ 1 ]-column.
        prog = unit_info-parent_main_program.
      ENDIF.

      DATA(mapping_options) = adt_tools_factory->create_mapping_options( ).
      mapping_options->set_use_package( abap_true ).
      TRY.
          DATA(obj_ref) = uri_mapper->map_include_to_objref(
            program     = prog
            include     = unit_info-include
            line        = line
            line_offset = col ).
          result = obj_ref->ref_data-uri.
        CATCH cx_adt_uri_mapping.
      ENDTRY.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
