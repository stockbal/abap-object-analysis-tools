"! <p class="shorttext synchronized" lang="en">Wrapper around ABAP compiler</p>
CLASS zcl_advoat_abap_compiler DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_advoat_abap_compiler.

    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Retrieves compiler instance by main program name</p>
      get
        IMPORTING
          main_prog     TYPE progname
          cache_active  TYPE abap_bool OPTIONAL
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_abap_compiler.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_compiler_cache,
        main_prog TYPE progname,
        compiler  TYPE REF TO zif_advoat_abap_compiler,
      END OF ty_compiler_cache.

    CLASS-DATA:
      compiler_cache TYPE HASHED TABLE OF ty_compiler_cache WITH UNIQUE KEY main_prog.

    DATA:
      main_prog     TYPE progname,
      abap_compiler TYPE REF TO cl_abap_compiler.

    METHODS:
      constructor
        IMPORTING
          main_prog TYPE progname.
ENDCLASS.



CLASS zcl_advoat_abap_compiler IMPLEMENTATION.

  METHOD get.
    CHECK main_prog IS NOT INITIAL.

    IF cache_active = abap_true.
      DATA(cached_instance) = REF #( compiler_cache[ main_prog = main_prog ] OPTIONAL ).
      IF cached_instance IS INITIAL.
        INSERT VALUE #(
            main_prog = main_prog
            compiler  = NEW zcl_advoat_abap_compiler( main_prog )
          ) INTO TABLE compiler_cache REFERENCE INTO cached_instance.
      ENDIF.
      result = cached_instance->compiler.
    ELSE.
      result = NEW zcl_advoat_abap_compiler( main_prog ).
    ENDIF.

  ENDMETHOD.


  METHOD constructor.
    me->main_prog = main_prog.
    abap_compiler = NEW cl_abap_compiler( p_name = main_prog ).
  ENDMETHOD.

  METHOD zif_advoat_abap_compiler~get_src_by_start_end_refs.
    abap_compiler->get_single_ref(
      EXPORTING
        p_full_names = VALUE #( ( full_name = full_name && '\SE:BEGIN\EI' grade = cl_abap_compiler=>grade_direct )
                                ( full_name = full_name && '\SE:END\EI'   grade = cl_abap_compiler=>grade_direct ) )
        p_extended   = abap_true
      IMPORTING
        p_result     = DATA(begin_end_refs)
      EXCEPTIONS
        OTHERS       = 1 ).

    IF lines( begin_end_refs ) = 2.
      " safety sort the refs
      SORT begin_end_refs BY line column.

      DATA(unit_begin_ref) = begin_end_refs[ 1 ].

      result = VALUE #(
        include = unit_begin_ref-statement->source_info->name
        start_pos = VALUE #(
          line   = begin_end_refs[ 1 ]-line
          column = begin_end_refs[ 1 ]-column )
        end_pos = VALUE #(
          line   = begin_end_refs[ 2 ]-line
          column = begin_end_refs[ 2 ]-column ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_advoat_abap_compiler~get_full_name_for_position.
    abap_compiler->get_full_name_for_position(
      EXPORTING
        p_include                  = include
        p_line                     = line
        p_column                   = column
      IMPORTING
        p_full_name                = result-full_name
        p_tag                      = result-tag
        p_grade                    = result-grade
      EXCEPTIONS
        include_not_found          = 1
        object_not_found           = 2
        program_fatal_syntax_error = 3
        OTHERS                     = 4 ).
  ENDMETHOD.


  METHOD zif_advoat_abap_compiler~get_refs_by_fullname.
    abap_compiler->get_single_ref(
      EXPORTING
        p_full_name  = full_name
        p_grade      = grade
        p_only_first = abap_false
        p_extended   = abap_true
      IMPORTING
        p_result     = result
      EXCEPTIONS
        OTHERS       = 1 ).
  ENDMETHOD.


  METHOD zif_advoat_abap_compiler~get_refs_by_fullnames.
    abap_compiler->get_single_ref(
      EXPORTING
        p_full_names = full_names
        p_only_first = abap_false
        p_extended   = abap_true
      IMPORTING
        p_result     = result
      EXCEPTIONS
        OTHERS       = 1 ).
  ENDMETHOD.


  METHOD zif_advoat_abap_compiler~get_symbol_entry.
    result = abap_compiler->get_symbol_entry( p_full_name = full_name ).
  ENDMETHOD.


  METHOD zif_advoat_abap_compiler~get_refs_in_range.
    abap_compiler->get_full_names_for_range(
      EXPORTING
        p_include           = include
        p_line_from         = start_line
        p_line_to           = end_line
      IMPORTING
        p_names_tags_grades = result
      EXCEPTIONS
        OTHERS              = 1 ).

    DELETE result WHERE ( tag <> cl_abap_compiler=>tag_method AND
                          tag <> cl_abap_compiler=>tag_function AND
                          tag <> cl_abap_compiler=>tag_form )
                     OR grade <> cl_abap_compiler=>grade_direct.
  ENDMETHOD.


  METHOD zif_advoat_abap_compiler~get_direct_references.
    abap_compiler->get_single_ref(
      EXPORTING
        p_full_name = full_name
        p_grade     = cl_abap_compiler=>grade_direct
        p_extended  = abap_true
      IMPORTING
        p_result    = result
      EXCEPTIONS
        OTHERS      = 1 ).

    DELETE result WHERE line < start_line
                     OR line > end_line
                     OR grade <> cl_abap_compiler=>grade_direct.

    SORT result BY line.
  ENDMETHOD.

ENDCLASS.
