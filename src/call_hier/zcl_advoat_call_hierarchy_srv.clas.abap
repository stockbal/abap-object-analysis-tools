"! <p class="shorttext synchronized" lang="en">Call Hierarchy Service</p>
CLASS zcl_advoat_call_hierarchy_srv DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_advoat_call_hierarchy.

  PUBLIC SECTION.
    INTERFACES zif_advoat_call_hierarchy_srv.

    METHODS:
      constructor
        IMPORTING
          comp_unit_factory TYPE REF TO zif_advoat_comp_unit_factory.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_comp_unit_by_line,
        line TYPE i,
        ref  TYPE REF TO zif_advoat_compilation_unit,
      END OF ty_comp_unit_by_line.

    CLASS-DATA:
      instance TYPE REF TO zif_advoat_call_hierarchy_srv.

    DATA:
      factory        TYPE REF TO zif_advoat_comp_unit_factory,
      unit_data      TYPE zif_advoat_ty_calh=>ty_compilation_unit,
      refs_for_range TYPE scr_names_tags_grades,
      called_include TYPE program,
      compiler       TYPE REF TO zif_advoat_abap_compiler,
      parser         TYPE REF TO zcl_advoat_abap_parser.

    METHODS:
      get_full_names_in_range,
      create_comp_unit
        IMPORTING
          direct_ref           TYPE scr_ref
          direct_ref_elem_info TYPE REF TO cl_abap_cc_prog_object
          full_name            TYPE string
          line_of_first_occ    TYPE i
          call_positions       TYPE zif_advoat_ty_calh=>ty_call_positions
        RETURNING
          VALUE(result)        TYPE REF TO zif_advoat_compilation_unit
        RAISING
          zcx_advoat_exception,
      create_comp_units_from_refs
        RETURNING
          VALUE(result) TYPE zif_advoat_compilation_unit=>ty_ref_tab,
      adjust_meth_full_name
        CHANGING
          full_name TYPE string,
      get_direct_references
        IMPORTING
          full_name     TYPE string
        RETURNING
          VALUE(result) TYPE scr_refs,
      get_call_positions
        IMPORTING
          refs          TYPE scr_refs
        RETURNING
          VALUE(result) TYPE zif_advoat_ty_calh=>ty_call_positions,
      filter_refs_by_include
        IMPORTING
          include       TYPE progname
          refs          TYPE scr_refs
        RETURNING
          VALUE(result) TYPE scr_refs,
      fill_legacy_type
        IMPORTING
          full_name     TYPE string
        CHANGING
          comp_unit     TYPE zif_advoat_ty_calh=>ty_compilation_unit
        RETURNING
          VALUE(result) TYPE seu_stype.
ENDCLASS.



CLASS zcl_advoat_call_hierarchy_srv IMPLEMENTATION.

  METHOD constructor.
    ASSERT comp_unit_factory IS BOUND.
    me->factory = comp_unit_factory.
    parser = NEW zcl_advoat_abap_parser( ).
  ENDMETHOD.


  METHOD zif_advoat_call_hierarchy_srv~determine_called_units.
    CHECK comp_unit->unit_info-main_program IS NOT INITIAL.

    unit_data = comp_unit->unit_info.
    compiler = zcl_advoat_abap_compiler=>get( unit_data-main_program ).

    get_full_names_in_range( ).
    IF refs_for_range IS INITIAL.
      RETURN.
    ENDIF.

    result = create_comp_units_from_refs( ).
  ENDMETHOD.


  METHOD get_full_names_in_range.
    IF unit_data-source_pos_start IS INITIAL.
      DATA(source_info) = compiler->get_src_by_start_end_refs( full_name = unit_data-full_name ).
      unit_data-include = source_info-include.
      unit_data-source_pos_start = source_info-start_pos.
      unit_data-source_pos_end = source_info-end_pos.
    ENDIF.

    refs_for_range = compiler->get_refs_in_range(
      include    = unit_data-include
      start_line = unit_data-source_pos_start-line + 1
      end_line   = unit_data-source_pos_end-line ).
  ENDMETHOD.


  METHOD create_comp_units_from_refs.

    DATA sorted_comp_units TYPE SORTED TABLE OF ty_comp_unit_by_line WITH NON-UNIQUE KEY line.

    LOOP AT refs_for_range ASSIGNING FIELD-SYMBOL(<ref>).

      DATA(direct_refs) = get_direct_references( <ref>-full_name ).
      CHECK direct_refs IS NOT INITIAL.

      DATA(call_positions) = get_call_positions( direct_refs ).
      DATA(line_of_first_occ) = call_positions[ 1 ]-line.

      DATA(original_full_name) = <ref>-full_name.
      IF <ref>-tag = cl_abap_compiler=>tag_method.
        adjust_meth_full_name( CHANGING full_name = original_full_name ).
      ENDIF.

      DATA(element_info) = parser->calculate_element_info( <ref>-full_name ).

      CHECK element_info IS BOUND.

      TRY.
          INSERT VALUE #(
            line = line_of_first_occ
            ref  = create_comp_unit(
              direct_ref           = direct_refs[ 1 ]
              direct_ref_elem_info = element_info
              full_name            = original_full_name
              line_of_first_occ    = line_of_first_occ
              call_positions       = call_positions ) ) INTO TABLE sorted_comp_units.
        CATCH zcx_advoat_exception.
      ENDTRY.

      DELETE refs_for_range.

    ENDLOOP.

    result = VALUE #( FOR <comp_unit> IN sorted_comp_units ( <comp_unit>-ref ) ).

  ENDMETHOD.


  METHOD create_comp_unit.

    DATA(new_unit_data) = VALUE zif_advoat_ty_calh=>ty_compilation_unit(
      tag                 = direct_ref-tag
      object_name         = direct_ref_elem_info->rawname
      full_name           = full_name
      description         = direct_ref_elem_info->shorttext
      include             = direct_ref-statement->source_info->name
      call_positions      = call_positions
      parent_main_program = unit_data-main_program ).

    IF direct_ref-tag = cl_abap_compiler=>tag_method.
      new_unit_data-method_props = parser->fill_method_information( element_info = direct_ref_elem_info ).
      new_unit_data-encl_object_type = parser->get_encl_method_type( full_name = direct_ref-full_name ).
    ENDIF.

    fill_legacy_type(
      EXPORTING
        full_name = direct_ref_elem_info->fullname
      CHANGING
        comp_unit = new_unit_data ).

    IF new_unit_data-legacy_type IS INITIAL.
      RETURN.
    ENDIF.

    result = factory->create_comp_unit( new_unit_data ).

  ENDMETHOD.


  METHOD adjust_meth_full_name.
    DATA(symbol) = compiler->get_symbol_entry( full_name ).
    IF symbol IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(method_symbol) = CAST cl_abap_comp_method( symbol ).
        IF method_symbol->compkind = cl_abap_comp_symbol=>compkind_alias AND
            method_symbol->super_method IS NOT INITIAL.
          full_name = method_symbol->super_method->full_name.
        ENDIF.
      CATCH cx_sy_move_cast_error.
    ENDTRY.
  ENDMETHOD.


  METHOD get_direct_references.
    result = compiler->get_direct_references(
      include    = unit_data-include
      full_name  = full_name
      start_line = unit_data-source_pos_start-line + 1
      end_line   = unit_data-source_pos_end-line ).

    result = filter_refs_by_include(
      include = unit_data-include
      refs    = result ).
  ENDMETHOD.


  METHOD filter_refs_by_include.

    LOOP AT refs ASSIGNING FIELD-SYMBOL(<ref>).
      TRY.
          DATA(include_of_source) = <ref>-statement->source_info->name.
          " include of occurence must match include of caller
          IF include <> include_of_source.
            CONTINUE.
          ENDIF.
        CATCH cx_sy_ref_is_initial.
          CONTINUE.
      ENDTRY.

      result = VALUE #( BASE result ( <ref> ) ).
    ENDLOOP.

  ENDMETHOD.


  METHOD get_call_positions.
    result = VALUE #( FOR <ref> IN refs ( line = <ref>-line column = <ref>-column ) ).
  ENDMETHOD.


  METHOD fill_legacy_type.
    DATA(ref_stack) = zcl_advoat_fullname_util=>get_parts( full_name ).

    CHECK lines( ref_stack ) >= 1.

    DATA(first_ref_entry) = ref_stack[ 1 ].
    DATA(second_ref_entry) = VALUE #( ref_stack[ 2 ] OPTIONAL ).

    IF first_ref_entry-tag = 'IN' OR
        first_ref_entry-tag = 'CL'.
      comp_unit-legacy_type = swbm_c_type_cls_mtd_impl.

      comp_unit-encl_object_name =
        comp_unit-encl_obj_display_name = first_ref_entry-name.
    ELSEIF first_ref_entry-tag = 'PR'.
      comp_unit-encl_object_name = first_ref_entry-name.

      IF second_ref_entry-tag = 'CL' OR
          second_ref_entry-tag = 'IN'.
        comp_unit-legacy_type = swbm_c_type_prg_class_method.

        DATA(encl_class) = translate( val = CONV seoclsname( first_ref_entry-name ) from = '=' to = '' ).
        comp_unit-encl_obj_display_name = |{ encl_class }=>{ second_ref_entry-name }|.
      ELSE.
        comp_unit-legacy_type = swbm_c_type_prg_subroutine.
        comp_unit-encl_obj_display_name = comp_unit-encl_object_name.
      ENDIF.
    ELSEIF first_ref_entry-tag = 'FU'.
      comp_unit-legacy_type = swbm_c_type_function.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
