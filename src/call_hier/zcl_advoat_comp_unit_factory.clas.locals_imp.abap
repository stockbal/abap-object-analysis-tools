*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lcl_intfm_src_pos_read_fac IMPLEMENTATION.

  METHOD create_reader_by_uri.
    DATA: main    TYPE progname,
          include TYPE progname.

    get_classnames_from_uri( EXPORTING uri     = uri
                             IMPORTING main    = main
                                       include = include ).
    IF main IS NOT INITIAL AND include IS NOT INITIAL.
      result = NEW lcl_class_intfm_src_pos_reader(
        full_name       = full_name
        uri             = uri
        method_name     = method_name
        source_position = source_position
        main_prog       = main
        include         = include ).
      RETURN.
    ENDIF.

    TRY.
        get_fugrnames_from_uri( EXPORTING uri     = uri
                                IMPORTING main    = main
                                          include = include ).
        IF main IS NOT INITIAL AND include IS NOT INITIAL.
          result = NEW lcl_incl_intfm_src_pos_reader(
            full_name       = full_name
            uri             = uri
            method_name     = method_name
            source_position = source_position
            main_prog       = main
            include         = include ).
          RETURN.
        ENDIF.
      CATCH zcx_advoat_not_exists.
        RETURN.
    ENDTRY.

    get_prognames_from_uri( EXPORTING uri     = uri
                            IMPORTING main    = main
                                      include = include ).

    IF main IS NOT INITIAL.
      result = NEW lcl_incl_intfm_src_pos_reader(
        full_name       = full_name
        uri             = uri
        method_name     = method_name
        source_position = source_position
        main_prog       = main
        include         = main ).
    ENDIF.
  ENDMETHOD.


  METHOD get_classnames_from_uri.
    FIND REGEX c_class_uri_regex IN uri
      RESULTS DATA(match).

    IF match IS INITIAL.
      RETURN.
    ENDIF.

    DATA(classname_group) = match-submatches[ 1 ].
    DATA(source_part1_group) = match-submatches[ 2 ].
    DATA(source_part2_group) = match-submatches[ 3 ].

    IF classname_group-offset <= 0 OR source_part1_group-offset <= 0.
      RETURN.
    ENDIF.

    DATA(classname) = CONV classname(
      to_upper(
        cl_http_utility=>unescape_url( |{ uri+classname_group-offset(classname_group-length) }| ) ) ).
    main = cl_oo_classname_service=>get_classpool_name( classname ).

    DATA(partname) = uri+source_part1_group-offset(source_part1_group-length).
    IF partname = 'source/main'.
      include = cl_oo_classname_service=>get_cs_name( classname ).
    ELSEIF partname = 'includes'.
      DATA(includename) = COND string( WHEN source_part2_group-offset > 0 THEN uri+source_part2_group-offset(source_part2_group-length) ).
      IF includename = 'definitions'.
        include = cl_oo_classname_service=>get_ccdef_name( classname ).
      ELSEIF includename = 'implementations'.
        include = cl_oo_classname_service=>get_ccimp_name( classname ).
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD get_fugrnames_from_uri.
    FIND REGEX c_fugr_uri_regex IN uri
      RESULTS DATA(match).

    IF match IS INITIAL.
      RETURN.
    ENDIF.

    DATA(fugrname_group) = match-submatches[ 1 ].
    DATA(type_group) = match-submatches[ 2 ].
    DATA(sub_name_group) = match-submatches[ 3 ].

    IF fugrname_group-offset <= 0 OR type_group-offset <= 0 OR sub_name_group-offset <= 0.
      RETURN.
    ENDIF.

    DATA(group) = cl_http_utility=>unescape_url( to_upper( uri+fugrname_group-offset(fugrname_group-length) ) ).
    main = zcl_advoat_func_util=>get_progname_for_group( CONV #( group ) ).
    include = cl_http_utility=>unescape_url( to_upper( uri+sub_name_group-offset(sub_name_group-length) ) ).

    DATA(type_name) = uri+type_group-offset(type_group-length).
    IF type_name = 'fmodules'.
      include = zcl_advoat_func_util=>get_function_include_by_fname( CONV #( include ) ).
    ENDIF.
  ENDMETHOD.


  METHOD get_prognames_from_uri.
    FIND REGEX c_prog_uri_regex IN uri
      RESULTS DATA(match).

    IF match IS INITIAL.
      RETURN.
    ENDIF.

    DATA(type_group) = match-submatches[ 1 ].
    DATA(name_group) = match-submatches[ 2 ].

    IF type_group-offset <= 0 OR name_group-offset <= 0.
      RETURN.
    ENDIF.

    main = cl_http_utility=>unescape_url( to_upper( uri+name_group-offset(name_group-length) ) ).

    DATA(type_name) = uri+type_group-offset(type_group-length).
    IF type_name = 'includes'.
      " TODO: differentiation necessary ??
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_class_intfm_src_pos_reader IMPLEMENTATION.

  METHOD constructor.
    super->constructor(
      full_name       = full_name
      uri             = uri
      method_name     = method_name
      source_position = source_position
      main_prog       = main_prog
      include         = include ).

    classname = main_prog.
    TRANSLATE classname USING '= '.
    is_main = xsdbool( include+30(2) = seop_ext_class_source ).
  ENDMETHOD.


  METHOD lif_intfm_source_pos_reader~determine_source_pos.
    DATA method_name TYPE seocpdname.

    IF NOT read_source( include ).
      RETURN. " TODO: Exception???
    ENDIF.

    TRY.
        DATA(source_line) = source_code[ source_position-line ].
      CATCH cx_sy_itab_line_not_found.
        RETURN. " TODO: Exception ???
    ENDTRY.

    IF is_method_impl_start( EXPORTING source_line = source_line
                             IMPORTING method_name = method_name ).
      IF is_main = abap_true.
        resolved_src_info = VALUE #(
          include   = cl_oo_classname_service=>get_method_include( mtdkey = VALUE #( clsname = classname cpdname = method_name ) )
          start_pos = VALUE #( line = 1 )
          end_pos   = VALUE #( line = 1000000 ) ).
      ELSE.
        encl_method_end_line = find_enclosing_meth_end( ).
        resolved_src_info = VALUE #(
          include = include
          start_pos = source_position
          end_pos   = VALUE #( line = encl_method_end_line ) ).
      ENDIF.
    ELSE.
      IF is_main = abap_false.
        " just check the current line in the include to detect the fullname
        resolve_target( include = include line = source_position-line ).
      ELSE.
        find_enclosing_meth_start( ).
        IF encl_method_start_line > 0.
          method_name = get_meth_name_from_impl_line( source_code[ encl_method_start_line ] ).
          resolve_target(
          " determine method include
            include = cl_oo_classname_service=>get_method_include( mtdkey = VALUE #( clsname = classname cpdname = method_name ) )
            line    = source_position-line - encl_method_start_line + 1 ).
        ENDIF.
      ENDIF.
    ENDIF.

    result = resolved_src_info.

  ENDMETHOD.


  METHOD find_enclosing_meth_start.
    DATA(i) = source_position-line - 1.

    WHILE i > 0.
      ASSIGN source_code[ i ] TO FIELD-SYMBOL(<source_line>).
      IF <source_line> CP '*method *'.
        encl_method_start_line = i.
        EXIT.
      ENDIF.
      i = i - 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD get_sanitized_mainprog_name.
    result = classname.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_incl_intfm_src_pos_reader IMPLEMENTATION.

  METHOD lif_intfm_source_pos_reader~determine_source_pos.
    DATA method_name TYPE seocpdname.

    IF NOT read_source( include ).
      RETURN. " TODO: Exception???
    ENDIF.

    TRY.
        DATA(source_line) = source_code[ source_position-line ].
      CATCH cx_sy_itab_line_not_found.
        RETURN. " TODO: Exception ???
    ENDTRY.

    IF is_method_impl_start( EXPORTING source_line = source_line
                             IMPORTING method_name = method_name ).
      DATA(meth_impl_end) = find_enclosing_meth_end( ).
      resolved_src_info = VALUE #(
        include   = main_prog
        start_pos = VALUE #( line = source_position-line )
        end_pos   = VALUE #( line = meth_impl_end ) ).
    ELSE.
      " just check the current line in the include to detect the fullname
      resolve_target( include = include line = source_position-line ).
    ENDIF.

    result = resolved_src_info.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_intfm_src_pos_reader_base IMPLEMENTATION.

  METHOD constructor.
    me->main_prog = main_prog.
    me->full_name = full_name.
    me->orig_uri = uri.
    me->ref_method_name = method_name.
    me->include = include.
    me->source_position = source_position.
  ENDMETHOD.


  METHOD resolve_target.
    DATA(compiler) = zcl_advoat_abap_compiler=>get( main_prog = main_prog ).
    DATA(refs) = compiler->get_refs_in_range(
      include    = include
      start_line = line
      end_line   = line ).

    IF lines( refs ) <> 1.
      RETURN.
    ENDIF.

    DATA(correct_full_name) = refs[ 1 ]-full_name.

    DATA(full_name_diff_offset) = find( val = correct_full_name sub = full_name ).
    IF full_name_diff_offset <= 0.
      IF strlen( correct_full_name ) = strlen( full_name ).
        resolve_by_navigation( ).
      ENDIF.
      RETURN.
    ENDIF.

    DATA(full_name_prefix) = correct_full_name(full_name_diff_offset).
    DATA(full_name_info) = zcl_advoat_fullname_util=>get_info_obj( full_name_prefix ).

    DATA(first_part) = full_name_info->get_first_part( ).
    IF first_part-key = cl_abap_compiler=>tag_program.
      IF first_part-value = main_prog.
        resolved_src_info = compiler->get_src_by_start_end_refs( correct_full_name ).
      ENDIF.
    ELSEIF first_part-key = cl_abap_compiler=>tag_type.
      resolved_src_info = VALUE #(
        include   = cl_oo_classname_service=>get_method_include( VALUE #( clsname = first_part-value cpdname = ref_method_name ) )
        start_pos = VALUE #( line = 1 )
        end_pos   = VALUE #( line = 1000000 ) ).

      IF first_part-value <> get_sanitized_mainprog_name( ).
        resolved_src_info-main_prog = cl_oo_classname_service=>get_classpool_name( CONV #( first_part-value ) ).
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD resolve_by_navigation.
    TRY.
        DATA(target_uri) = zcl_advoat_adt_nav_util=>navigate_by_uri(
          uri    = orig_uri
          source = source_code ).
      CATCH zcx_advoat_exception.
        RETURN.
    ENDTRY.

    DATA(reader) = lcl_intfm_src_pos_read_fac=>create_reader_by_uri(
      uri             = target_uri
      method_name     = ref_method_name
      full_name       = full_name
      source_position = zcl_advoat_adt_uri_util=>get_uri_source_start_pos( target_uri ) ).

    IF reader IS BOUND.
      resolved_src_info = reader->determine_source_pos( ).
      IF resolved_src_info IS NOT INITIAL.
        resolved_src_info-main_prog = CAST lcl_intfm_src_pos_reader_base( reader )->main_prog.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD find_enclosing_meth_end.

    LOOP AT source_code ASSIGNING FIELD-SYMBOL(<source_line>) FROM source_position-line + 1
                                                              WHERE table_line CP '*endmethod.*'.
      result = sy-tabix.
      EXIT.
    ENDLOOP.

  ENDMETHOD.

  METHOD is_method_impl_start.
    method_name = get_meth_name_from_impl_line( source_line ).
    result = xsdbool( method_name IS NOT INITIAL ).
  ENDMETHOD.


  METHOD get_meth_name_from_impl_line.
    FIND REGEX `\s*method\s+([\w+~/]+)\s*\.` IN source_line
      IGNORING CASE
      RESULTS DATA(match).

    IF match IS INITIAL.
      RETURN.
    ENDIF.
    DATA(method_name_group) = match-submatches[ 1 ].
    result = to_upper( source_line+method_name_group-offset(method_name_group-length) ).
  ENDMETHOD.


  METHOD read_source.
    READ REPORT source_name INTO source_code.
    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.


  METHOD get_sanitized_mainprog_name.
    result = main_prog.
  ENDMETHOD.

ENDCLASS.
