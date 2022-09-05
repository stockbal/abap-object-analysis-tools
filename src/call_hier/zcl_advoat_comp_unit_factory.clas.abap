"! <p class="shorttext synchronized" lang="en">Compilation unit factory</p>
CLASS zcl_advoat_comp_unit_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_advoat_comp_unit_factory.

    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Retrieves factory instance</p>
      get_instance
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_comp_unit_factory.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA:
      instance TYPE REF TO zif_advoat_comp_unit_factory,
      parser   TYPE REF TO zcl_advoat_abap_parser.

    DATA:
      relevant_legacy_types TYPE RANGE OF seu_stype.

    METHODS:
      constructor,
      resolve_main_prog
        IMPORTING
          unit_data TYPE REF TO zif_advoat_ty_calh=>ty_compilation_unit,
      resolve_main_prog_ff
        IMPORTING
          unit_data TYPE REF TO zif_advoat_ty_calh=>ty_compilation_unit,
      resolve_main_prog_om
        IMPORTING
          unit_data TYPE REF TO zif_advoat_ty_calh=>ty_compilation_unit,
      get_adt_type
        IMPORTING
          unit_data     TYPE zif_advoat_ty_calh=>ty_compilation_unit
        RETURNING
          VALUE(result) TYPE string,
      adjust_main_prog
        IMPORTING
          unit_data      TYPE REF TO zif_advoat_ty_calh=>ty_compilation_unit
        EXPORTING
          is_adjusted    TYPE abap_bool
          encl_obj_descr TYPE REF TO cl_abap_typedescr
        RAISING
          zcx_advoat_exception,
      adjust_full_name
        IMPORTING
          unit_data      TYPE REF TO zif_advoat_ty_calh=>ty_compilation_unit
          encl_obj_descr TYPE REF TO cl_abap_typedescr,
      adjust_object_information
        IMPORTING
          unit_data TYPE REF TO zif_advoat_ty_calh=>ty_compilation_unit
        RAISING
          zcx_advoat_exception,
      determine_source_info
        IMPORTING
          uri               TYPE string
          source_pos_of_uri TYPE zif_advoat_ty_calh=>ty_source_position
          unit_data         TYPE REF TO zif_advoat_ty_calh=>ty_compilation_unit,
      determine_src_info_by_uri
        IMPORTING
          uri               TYPE string
          source_pos_of_uri TYPE zif_advoat_ty_calh=>ty_source_position
          unit_data         TYPE REF TO zif_advoat_ty_calh=>ty_compilation_unit
        RETURNING
          VALUE(result)     TYPE zif_advoat_ty_calh=>ty_cu_src_info.
ENDCLASS.



CLASS zcl_advoat_comp_unit_factory IMPLEMENTATION.

  METHOD constructor.
    parser = NEW #( ).
    relevant_legacy_types = VALUE #( sign = 'I' option = 'EQ'
      ( low = zif_advoat_c_euobj_type=>form )
      ( low = zif_advoat_c_euobj_type=>function )
      ( low = zif_advoat_c_euobj_type=>method )
      ( low = zif_advoat_c_euobj_type=>local_impl_method ) ).
  ENDMETHOD.


  METHOD get_instance.
    IF instance IS INITIAL.
      instance = NEW zcl_advoat_comp_unit_factory( ).
    ENDIF.

    result = instance.
  ENDMETHOD.


  METHOD zif_advoat_comp_unit_factory~create_comp_unit.
    DATA(l_unit_data) = unit_data.
    IF l_unit_data-main_program IS INITIAL.
      resolve_main_prog( REF #( l_unit_data ) ).
    ENDIF.

    l_unit_data-adt_type = get_adt_type( l_unit_data ).

    result = NEW zcl_advoat_compilation_unit(
      data              = l_unit_data
      hierarchy_service = zcl_advoat_call_hierarchy=>get_call_hierarchy_srv( ) ).
  ENDMETHOD.


  METHOD zif_advoat_comp_unit_factory~create_comp_unit_from_ext.
    IF data_request-orig_request-legacy_type NOT IN relevant_legacy_types.
      RAISE EXCEPTION TYPE zcx_advoat_exception.
    ENDIF.

    DATA(unit_data) = CORRESPONDING zif_advoat_ty_calh=>ty_compilation_unit( data_request-orig_request ).

    adjust_object_information( REF #( unit_data ) ).

    " should always be filled when coming from URI ???
**    IF unit_data->main_program IS INITIAL.
**      resolve_main_prog( CHANGING unit_data = unit_data ).
**    ENDIF.

    IF unit_data-main_program IS INITIAL.
      RAISE EXCEPTION TYPE zcx_advoat_exception.
    ENDIF.

    unit_data-tag = zcl_advoat_fullname_util=>get_info_obj( unit_data-full_name )->get_abap_fullname_tag( ).

    IF unit_data-tag = cl_abap_compiler=>tag_method.
      DATA(element_info) = parser->calculate_element_info( full_name = unit_data-full_name ).

      IF element_info IS NOT INITIAL.
        unit_data-full_name_from_parser = element_info->fullname.
        unit_data-method_props = parser->fill_method_information( element_info = element_info ).
        unit_data-encl_object_type = parser->get_encl_method_type( unit_data-full_name ).
      ENDIF.
    ENDIF.

    determine_source_info(
      uri               = data_request-uri
      source_pos_of_uri = data_request-source_pos_of_uri
      unit_data         = REF #( unit_data ) ).

    unit_data-adt_type = get_adt_type( unit_data ).

    DATA(comp_unit) = NEW zcl_advoat_compilation_unit(
      data              = unit_data
      hierarchy_service = zcl_advoat_call_hierarchy=>get_call_hierarchy_srv( ) ).

    IF unit_data-source_pos_start IS INITIAL.
      comp_unit->set_hierarchy_possible( abap_false ).
    ENDIF.

    result = comp_unit.

  ENDMETHOD.


  METHOD resolve_main_prog.
    CASE unit_data->legacy_type.

      WHEN swbm_c_type_function.
        resolve_main_prog_ff( unit_data ).
        IF unit_data->full_name IS INITIAL.
          unit_data->full_name = |\\{ cl_abap_compiler=>tag_function }:{ unit_data->object_name }|.
        ENDIF.

      WHEN swbm_c_type_cls_mtd_impl.
        resolve_main_prog_om( unit_data ).

      WHEN swbm_c_type_prg_subroutine.

        IF unit_data->main_program IS INITIAL.
          unit_data->main_program = unit_data->encl_object_name.
        ENDIF.

      WHEN swbm_c_type_prg_class_method.

        IF unit_data->main_program IS INITIAL AND unit_data->encl_object_type <> 'INTF'.
          unit_data->main_program = unit_data->encl_object_name.
        ENDIF.

    ENDCASE.
  ENDMETHOD.


  METHOD resolve_main_prog_ff.
    CHECK unit_data->main_program IS INITIAL.
    DATA(funcname) = CONV rs38l_fnam( unit_data->object_name ).
    CALL FUNCTION 'FUNCTION_INCLUDE_INFO'
      IMPORTING
        pname    = unit_data->main_program
      CHANGING
        funcname = funcname
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
    ENDIF.
  ENDMETHOD.


  METHOD resolve_main_prog_om.
    CHECK unit_data->main_program IS INITIAL.
    IF unit_data->encl_object_name+30(2) = 'CP'.
      unit_data->main_program = unit_data->encl_object_name.
    ELSE.
      cl_abap_typedescr=>describe_by_name( EXPORTING  p_name      = unit_data->encl_object_name
                                           RECEIVING  p_descr_ref = DATA(typedescr)
                                           EXCEPTIONS OTHERS      = 1 ).
      IF sy-subrc = 0.
        DATA(class_typedescr) = CAST cl_abap_objectdescr( typedescr ).
        IF class_typedescr->kind = cl_abap_typedescr=>kind_class.
          unit_data->main_program = cl_oo_classname_service=>get_classpool_name( CONV #( unit_data->encl_object_name ) ).
        ELSE.
          " check if full name has the class name in the front
          DATA(name_parts) = zcl_advoat_fullname_util=>get_parts( unit_data->full_name ).
          IF lines( name_parts ) >= 2 AND name_parts[ 2 ]-name = unit_data->encl_object_name.
            cl_abap_typedescr=>describe_by_name( EXPORTING  p_name      = name_parts[ 1 ]-name
                                                 RECEIVING  p_descr_ref = DATA(encl_class_descr)
                                                 EXCEPTIONS OTHERS      = 1 ).
            IF sy-subrc = 0 AND encl_class_descr->kind = cl_abap_typedescr=>kind_class.

              DATA(interfaces) = CAST cl_abap_classdescr( encl_class_descr )->interfaces.
              IF interfaces IS NOT INITIAL AND
                  line_exists( interfaces[ name = unit_data->encl_object_name ] ).
                unit_data->main_program = cl_oo_classname_service=>get_classpool_name(
                  CONV #( CAST cl_abap_objectdescr( encl_class_descr )->get_relative_name( ) ) ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSE.
        MESSAGE |Type { unit_data->encl_object_name } not found!| TYPE 'E'.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD get_adt_type.
    DATA tadir_type TYPE trobjtype.

    CASE unit_data-legacy_type.
      WHEN zif_advoat_c_euobj_type=>form OR
           zif_advoat_c_euobj_type=>local_impl_method.
        tadir_type = zif_advoat_c_tadir_type=>program.

      WHEN zif_advoat_c_euobj_type=>function.
        tadir_type = zif_advoat_c_tadir_type=>function_group.

      WHEN zif_advoat_c_euobj_type=>method.
        tadir_type = zif_advoat_c_tadir_type=>class.
    ENDCASE.

    result = |{ tadir_type }/{ unit_data-legacy_type }|.
  ENDMETHOD.


  METHOD adjust_object_information.
    CHECK unit_data->main_program IS NOT INITIAL.

    DATA(is_mainp_not_encl_obj) = xsdbool( unit_data->main_program NP |{ unit_data->encl_object_name }*| ).

    IF is_mainp_not_encl_obj = abap_true.
      adjust_main_prog( EXPORTING unit_data      = unit_data
                        IMPORTING encl_obj_descr = DATA(encl_obj_descr)
                                  is_adjusted    = DATA(is_main_prog_adjusted) ).
    ENDIF.

    IF encl_obj_descr IS BOUND AND is_mainp_not_encl_obj = abap_true.
      adjust_full_name( EXPORTING unit_data      = unit_data
                                  encl_obj_descr = encl_obj_descr ).
    ENDIF.
  ENDMETHOD.


  METHOD adjust_main_prog.
    IF unit_data->encl_object_name+30(2) = 'CP'.
      unit_data->main_program = unit_data->encl_object_name.
    ELSE.
      cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = unit_data->encl_object_name
                                           RECEIVING  p_descr_ref    = encl_obj_descr
                                           EXCEPTIONS type_not_found = 1
                                                      OTHERS         = 2 ).
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE zcx_advoat_exception.
      ELSE.
        IF encl_obj_descr->kind = cl_abap_typedescr=>kind_class.
          unit_data->main_program = cl_oo_classname_service=>get_classpool_name( CONV #( unit_data->encl_object_name ) ).
          is_adjusted = abap_true.
        ELSE.
          " adjustment of full name needed???
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD adjust_full_name.

    IF encl_obj_descr->kind = cl_abap_typedescr=>kind_intf.

      " 1) check if main program cont
    ENDIF.

  ENDMETHOD.


  METHOD determine_source_info.
    " TODO: check if unnecessary compiler call can be be prevented if alias call or interface method detected
    DATA(compiler) = zcl_advoat_abap_compiler=>get( main_prog = unit_data->main_program ).

    DATA(source_info) = compiler->get_src_by_start_end_refs( unit_data->full_name ).

    IF source_info IS INITIAL AND unit_data->tag = cl_abap_compiler=>tag_method.
      IF unit_data->method_props-is_alias = abap_true.
        DATA(refs) = compiler->get_refs_by_fullname( unit_data->full_name ).

        LOOP AT refs ASSIGNING FIELD-SYMBOL(<ref>) WHERE full_name = unit_data->full_name.
          DATA(method_symbol) = CAST cl_abap_comp_method( <ref>-symbol ).
          " handle alias method
          IF method_symbol->super_method IS NOT INITIAL.
            DATA(super_full_name) = method_symbol->super_method->full_name.
            source_info = compiler->get_src_by_start_end_refs( super_full_name ).
            EXIT.
          ENDIF.
        ENDLOOP.
      ELSEIF unit_data->encl_object_type = zif_advoat_c_tadir_type=>interface.
        " handle interface method call
        source_info = determine_src_info_by_uri(
          uri               = uri
          source_pos_of_uri = source_pos_of_uri
          unit_data         = unit_data ).
      ENDIF.
    ENDIF.

    IF source_info-main_prog IS NOT INITIAL.
      unit_data->main_program = source_info-main_prog.
    ENDIF.
    unit_data->include = source_info-include.
    unit_data->source_pos_start = source_info-start_pos.
    unit_data->source_pos_end = source_info-end_pos.
  ENDMETHOD.


  METHOD determine_src_info_by_uri.
    DATA source_code TYPE string_table.

    DATA(source_reader) = lcl_intfm_src_pos_read_fac=>create_reader_by_uri(
      uri             = uri
      method_name     = |{ unit_data->encl_object_name }~{ unit_data->object_name }|
      full_name       = unit_data->full_name_from_parser
      source_position = source_pos_of_uri ).
    IF source_reader IS INITIAL.
      RETURN.
    ENDIF.

    result = source_reader->determine_source_pos( ).
  ENDMETHOD.

ENDCLASS.
