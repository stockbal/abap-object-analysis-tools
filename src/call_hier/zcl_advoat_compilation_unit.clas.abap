"! <p class="shorttext synchronized" lang="en">Compilation unit</p>
CLASS zcl_advoat_compilation_unit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_advoat_compilation_unit.

    METHODS:
      constructor
        IMPORTING
          data TYPE zif_advoat_ty_calh=>ty_compilation_unit
        RAISING
          zcx_advoat_exception.
  PROTECTED SECTION.
  PRIVATE SECTION.
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
      unit_data      TYPE zif_advoat_ty_calh=>ty_compilation_unit,
      refs_for_range TYPE scr_names_tags_grades,
      called_include TYPE program,
      compiler       TYPE REF TO cl_abap_compiler,
      src_pos_start  TYPE i,
      src_pos_end    TYPE scr_ref-line,
      parser         TYPE REF TO cl_abap_parser.

    METHODS:
      determine_called_comp_units
        RETURNING
          VALUE(result) TYPE zif_advoat_compilation_unit=>ty_ref_tab,
      resolve_main_prog,
      resolve_main_prog_ff,
      resolve_main_prog_om,
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

      get_ref_stack_from_name
        IMPORTING
          full_name     TYPE string
        RETURNING
          VALUE(result) TYPE ty_ref_stack,

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

      fill_method_information
        IMPORTING
          element_info TYPE REF TO cl_abap_cc_prog_object
        CHANGING
          comp_unit    TYPE zif_advoat_ty_calh=>ty_compilation_unit,
      fill_legacy_type
        IMPORTING
          full_name     TYPE string
        CHANGING
          comp_unit     TYPE zif_advoat_ty_calh=>ty_compilation_unit
        RETURNING
          VALUE(result) TYPE seu_stype,
      get_encl_method_type
        IMPORTING
          full_name     TYPE scr_ref-full_name
        RETURNING
          VALUE(result) TYPE trobjtype.
ENDCLASS.



CLASS zcl_advoat_compilation_unit IMPLEMENTATION.

  METHOD constructor.
    me->unit_data = data.
  ENDMETHOD.


  METHOD zif_advoat_compilation_unit~get_call_positions.
    result = unit_data-call_positions.
  ENDMETHOD.


  METHOD zif_advoat_compilation_unit~get_include.
    result = unit_data-include.
  ENDMETHOD.


  METHOD zif_advoat_compilation_unit~get_called_units.
*    CHECK unit_data-encl_object_type <> 'INTF'.

    IF unit_data-main_program IS INITIAL.
      resolve_main_prog( ).
      IF unit_data-main_program IS INITIAL.
        RETURN.
      ENDIF.
    ENDIF.


    result = determine_called_comp_units( ).
  ENDMETHOD.


  METHOD zif_advoat_compilation_unit~get_encl_object_name.
    result = unit_data-encl_object_name.
  ENDMETHOD.


  METHOD zif_advoat_compilation_unit~get_encl_obj_display_name.
    result = unit_data-encl_obj_display_name.
  ENDMETHOD.


  METHOD zif_advoat_compilation_unit~get_simple_name.
    result = unit_data-object_name.
  ENDMETHOD.


  METHOD zif_advoat_compilation_unit~get_full_name.
    result = unit_data-full_name.
  ENDMETHOD.


  METHOD zif_advoat_compilation_unit~get_type.
    result = unit_data-legacy_type.
  ENDMETHOD.


  METHOD zif_advoat_compilation_unit~get_visibility.
    result = unit_data-visibility.
  ENDMETHOD.


  METHOD zif_advoat_compilation_unit~get_description.
    result = unit_data-description.
  ENDMETHOD.


  METHOD resolve_main_prog.
    CASE unit_data-legacy_type.

      WHEN swbm_c_type_function.
        resolve_main_prog_ff( ).
        IF unit_data-full_name IS INITIAL.
          unit_data-full_name = |\\{ cl_abap_compiler=>tag_function }:{ unit_data-object_name }|.
        ENDIF.

      WHEN swbm_c_type_cls_mtd_impl.
        resolve_main_prog_om( ).

      WHEN swbm_c_type_prg_subroutine.

        IF unit_data-main_program IS INITIAL.
          unit_data-main_program = unit_data-encl_object_name.
        ENDIF.

      WHEN swbm_c_type_prg_class_method.

        IF unit_data-main_program IS INITIAL AND unit_data-encl_object_type <> 'INTF'.
          unit_data-main_program = unit_data-encl_object_name.
        ENDIF.

    ENDCASE.
  ENDMETHOD.


  METHOD resolve_main_prog_ff.
    CHECK unit_data-main_program IS INITIAL.
    DATA(funcname) = CONV rs38l_fnam( unit_data-object_name ).
    CALL FUNCTION 'FUNCTION_INCLUDE_INFO'
      IMPORTING
        pname    = unit_data-main_program
      CHANGING
        funcname = funcname
        include  = called_include
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
    ENDIF.
  ENDMETHOD.


  METHOD resolve_main_prog_om.
    CHECK unit_data-main_program IS INITIAL.
    IF unit_data-encl_object_name+30(2) = 'CP'.
      unit_data-main_program = unit_data-encl_object_name.
    ELSE.
      cl_abap_typedescr=>describe_by_name(
        EXPORTING
          p_name      = unit_data-encl_object_name
        RECEIVING
          p_descr_ref = DATA(typedescr)
        EXCEPTIONS
          OTHERS      = 1 ).
      IF sy-subrc = 0.
        DATA(class_typedescr) = CAST cl_abap_objectdescr( typedescr ).
        IF class_typedescr->kind = cl_abap_typedescr=>kind_class.
          unit_data-main_program = cl_oo_classname_service=>get_classpool_name( CONV #( unit_data-encl_object_name ) ).
        ELSE.
          " check if full name has the class name in the front
          DATA(name_parts) = get_ref_stack_from_name( unit_data-full_name ).
          IF lines( name_parts ) >= 2 AND name_parts[ 2 ]-name = unit_data-encl_object_name.
            cl_abap_typedescr=>describe_by_name(
              EXPORTING
                p_name      = name_parts[ 1 ]-name
              RECEIVING
                p_descr_ref = DATA(encl_class_descr)
              EXCEPTIONS
                OTHERS      = 1 ).
            IF sy-subrc = 0 AND encl_class_descr->kind = cl_abap_typedescr=>kind_class.

              DATA(interfaces) = CAST cl_abap_classdescr( encl_class_descr )->interfaces.
              IF interfaces IS NOT INITIAL AND
                  line_exists( interfaces[ name = unit_data-encl_object_name ] ).
                unit_data-main_program = cl_oo_classname_service=>get_classpool_name(
                  CONV #( CAST cl_abap_objectdescr( encl_class_descr )->get_relative_name( ) ) ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSE.
        MESSAGE |Type { unit_data-encl_object_name } not found!| TYPE 'E'.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD determine_called_comp_units.
    IF compiler IS INITIAL.
      compiler = NEW cl_abap_compiler( p_name = unit_data-main_program ).
      parser = NEW cl_abap_parser( ).
    ENDIF.

    get_full_names_in_range( ).
    IF refs_for_range IS INITIAL.
      RETURN.
    ENDIF.

    result = create_comp_units_from_refs( ).
  ENDMETHOD.


  METHOD get_full_names_in_range.
    compiler->get_single_ref(
      EXPORTING
        p_full_name = |{ unit_data-full_name }\\SE:BEGIN\\EI|
        p_grade     = cl_abap_compiler=>grade_direct
        p_extended  = abap_true
      IMPORTING
        p_result    = DATA(unit_begin)
      EXCEPTIONS
        OTHERS      = 1 ).

    IF unit_begin IS INITIAL.
      compiler->get_single_ref(
        EXPORTING
          p_full_name  = unit_data-full_name
          p_grade      = cl_abap_compiler=>grade_definition
          p_only_first = abap_true
          p_extended   = abap_true
        IMPORTING
          p_result     = unit_begin
        EXCEPTIONS
          OTHERS       = 1 ).
      IF sy-subrc = 0 AND unit_begin IS NOT INITIAL.
        DATA(statement) = unit_begin[ 1 ]-statement.
        src_pos_start = statement->start_line + 1.
        src_pos_end = 10000000. " probably too high, but just to be save
        unit_data-include = statement->source_info->name.
      ENDIF.
    ELSE.
      compiler->get_single_ref(
        EXPORTING
          p_full_name = |{ unit_data-full_name }\\SE:END\\EI|
          p_grade     = cl_abap_compiler=>grade_direct
          p_extended  = abap_true
        IMPORTING
          p_result    = DATA(unit_end)
        EXCEPTIONS
          OTHERS      = 1 ).

      DATA(unit_begin_ref) = unit_begin[ 1 ].

      src_pos_start = unit_begin[ 1 ]-line + 1.
      src_pos_end = unit_end[ 1 ]-line.

      unit_data-include = unit_begin_ref-statement->source_info->name.
    ENDIF.

    compiler->get_full_names_for_range(
      EXPORTING
        p_include           = unit_data-include
        p_line_from         = src_pos_start
        p_line_to           = src_pos_end
      IMPORTING
        p_names_tags_grades = refs_for_range
      EXCEPTIONS
        OTHERS              = 1 ).

    DELETE refs_for_range WHERE tag <> cl_abap_compiler=>tag_method
                            AND tag <> cl_abap_compiler=>tag_function
                            AND tag <> cl_abap_compiler=>tag_form.
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

      DATA(element_info) = parser->calculate_element_info_by_name(
        fullname = <ref>-full_name ).

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
      tag              = direct_ref-tag
      object_name      = direct_ref_elem_info->rawname
      full_name        = full_name
      description      = direct_ref_elem_info->shorttext
      include          = direct_ref-statement->source_info->name
      call_positions   = call_positions ).

    IF direct_ref-tag = cl_abap_compiler=>tag_method.
      fill_method_information(
        EXPORTING
          element_info = direct_ref_elem_info
        CHANGING
          comp_unit    = new_unit_data ).
      new_unit_data-encl_object_type = get_encl_method_type( full_name = direct_ref-full_name ).
    ENDIF.

    fill_legacy_type(
      EXPORTING
        full_name = direct_ref_elem_info->fullname
      CHANGING
        comp_unit = new_unit_data ).

    IF new_unit_data-legacy_type IS INITIAL.
      RETURN.
    ENDIF.

    result = NEW zcl_advoat_compilation_unit( data = new_unit_data ).

  ENDMETHOD.


  METHOD get_ref_stack_from_name.
    DATA: tokens TYPE string_table.

    SPLIT full_name AT '\' INTO TABLE tokens.

    LOOP AT tokens INTO DATA(token) WHERE table_line IS NOT INITIAL.
      DATA(type) = token(2).
      result = VALUE #( BASE result ( name = token+3
                                      type = token(2) ) ).
    ENDLOOP.

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
    compiler->get_single_ref(
      EXPORTING
        p_full_name = full_name
        p_grade     = cl_abap_compiler=>grade_direct
        p_extended  = abap_true
      IMPORTING
        p_result    = DATA(all_refs)
      EXCEPTIONS
        OTHERS      = 1 ).

    DELETE all_refs WHERE line < src_pos_start
                       OR line > src_pos_end
                       OR grade <> cl_abap_compiler=>grade_direct.
    IF all_refs IS INITIAL.
      RETURN.
    ENDIF.

    SORT all_refs BY line.

    LOOP AT all_refs ASSIGNING FIELD-SYMBOL(<direct_ref_for_name>).
      TRY.
          DATA(include) = <direct_ref_for_name>-statement->source_info->name.
          " include of occurence must match include of caller
          IF unit_data-include IS NOT INITIAL AND include <> unit_data-include.
            CONTINUE.
          ENDIF.
          result = VALUE #( BASE result ( <direct_ref_for_name> ) ).
        CATCH cx_sy_ref_is_initial.
          CONTINUE.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_call_positions.

    LOOP AT refs ASSIGNING FIELD-SYMBOL(<ref>).
      result = VALUE #( BASE result (
        line   = <ref>-line
        column = <ref>-column ) ).
    ENDLOOP.

  ENDMETHOD.


  METHOD fill_method_information.
    DATA(method_info) = CAST cl_abap_cc_method( element_info ).

    comp_unit-visibility = SWITCH #( method_info->visibility
      WHEN sccmp_visibility_private   THEN zif_advoat_c_calh_global=>c_visibility-private
      WHEN sccmp_visibility_protected THEN zif_advoat_c_calh_global=>c_visibility-protected
      WHEN sccmp_visibility_public    THEN zif_advoat_c_calh_global=>c_visibility-public ).

    comp_unit-method_props = VALUE #(
      is_abstract    = xsdbool( method_info->is_abstract = sccmp_true )
      is_constructor = xsdbool( method_info->is_constructor = sccmp_true )
      is_final       = xsdbool( method_info->is_final = sccmp_true )
      is_handler     = xsdbool( method_info->is_handler = sccmp_true )
      is_redefined   = xsdbool( method_info->is_redefined = sccmp_true )
      level          = SWITCH #( method_info->member_kind
        WHEN sccmp_member_class THEN zif_advoat_c_calh_global=>c_class_level-static
        ELSE zif_advoat_c_calh_global=>c_class_level-instance ) ).

  ENDMETHOD.


  METHOD fill_legacy_type.
    DATA(ref_stack) = get_ref_stack_from_name( full_name ).

    CHECK lines( ref_stack ) >= 1.

    DATA(first_ref_entry) = ref_stack[ 1 ].
    DATA(second_ref_entry) = VALUE #( ref_stack[ 2 ] OPTIONAL ).

    IF first_ref_entry-type = 'IN' OR
        first_ref_entry-type = 'CL'.
      comp_unit-legacy_type = swbm_c_type_cls_mtd_impl.

      comp_unit-encl_object_name =
        comp_unit-encl_obj_display_name = first_ref_entry-name.
    ELSEIF first_ref_entry-type = 'PR'.
      comp_unit-encl_object_name = first_ref_entry-name.

      IF second_ref_entry-type = 'CL' OR
          second_ref_entry-type = 'IN'.
        comp_unit-legacy_type = swbm_c_type_prg_class_method.

        DATA(encl_class) = translate( val = CONV seoclsname( first_ref_entry-name ) from = '=' to = '' ).
        comp_unit-encl_obj_display_name = |{ encl_class }=>{ second_ref_entry-name }|.
      ELSE.
        comp_unit-legacy_type = swbm_c_type_prg_subroutine.
        comp_unit-encl_obj_display_name = comp_unit-encl_object_name.
      ENDIF.
    ELSEIF first_ref_entry-type = 'FU'.
      comp_unit-legacy_type = swbm_c_type_function.
    ENDIF.
  ENDMETHOD.


  METHOD get_encl_method_type.
    DATA(tag_index) = find( val = full_name sub = '\ME' ).
    DATA(full_type_name) = full_name(tag_index).

    DATA(type_elem_info) = parser->calculate_element_info_by_name( fullname = full_type_name ).
    IF type_elem_info IS NOT INITIAL.
      result = COND #(
        WHEN type_elem_info->role = sccmp_role_classtype THEN 'CLAS'
        WHEN type_elem_info->role = sccmp_role_intftype THEN 'INTF' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
