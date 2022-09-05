*"* use this source file for any type of declarations (class
*"* definitions, interfaces or type declarations) you need for
*"* components in the private section
"! Reader for correct source position of a called interface method
INTERFACE lif_intfm_source_pos_reader.
  METHODS:
    determine_source_pos
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_calh=>ty_cu_src_info.
ENDINTERFACE.

CLASS lcl_intfm_src_pos_read_fac DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      create_reader_by_uri
        IMPORTING
          uri             TYPE string
          method_name     TYPE seocpdname
          full_name       TYPE string
          source_position TYPE zif_advoat_ty_calh=>ty_source_position
        RETURNING
          VALUE(result)   TYPE REF TO lif_intfm_source_pos_reader.
  PRIVATE SECTION.
    CONSTANTS:
      c_prog_uri_regex  TYPE string VALUE `^/sap/bc/adt/programs/(includes|programs)/([\w%]+)/source/main`,
      c_fugr_uri_regex  TYPE string VALUE `^/sap/bc/adt/functions/groups/([\w%]+)/(includes|fmodules)/([\w%]+)/source/main`,
      c_class_uri_regex TYPE string VALUE `^/sap/bc/adt/oo/classes/([\w%]+)/(source/main|includes)/?(definitions|implementations|testclasses)?`.

    CLASS-METHODS: get_classnames_from_uri
      IMPORTING
        uri     TYPE string
      EXPORTING
        main    TYPE progname
        include TYPE progname,
      get_fugrnames_from_uri
        IMPORTING
          uri     TYPE string
        EXPORTING
          main    TYPE progname
          include TYPE progname
        RAISING
          zcx_advoat_not_exists,
      get_prognames_from_uri
        IMPORTING
          uri     TYPE string
        EXPORTING
          main    TYPE progname
          include TYPE progname.
ENDCLASS.

CLASS lcl_intfm_src_pos_reader_base DEFINITION ABSTRACT.
  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING
          full_name       TYPE string
          uri             TYPE string
          method_name     TYPE seocpdname
          source_position TYPE zif_advoat_ty_calh=>ty_source_position
          main_prog       TYPE progname
          include         TYPE progname.
  PROTECTED SECTION.
    DATA:
      main_prog         TYPE progname,
      orig_uri          TYPE string,
      full_name         TYPE string,
      ref_method_name   TYPE seocpdname,
      encl_method_name  TYPE seocpdname,
      include           TYPE progname,
      resolved_src_info TYPE zif_advoat_ty_calh=>ty_cu_src_info,
      source_code       TYPE string_table,
      source_position   TYPE zif_advoat_ty_calh=>ty_source_position.

    METHODS:
      get_sanitized_mainprog_name
        RETURNING
          VALUE(result) TYPE progname,
      read_source
        IMPORTING
          source_name   TYPE progname
        RETURNING
          VALUE(result) TYPE abap_bool,
      get_meth_name_from_impl_line
        IMPORTING
          source_line   TYPE string
        RETURNING
          VALUE(result) TYPE string,
      is_method_impl_start
        IMPORTING
          source_line   TYPE string
        EXPORTING
          method_name   TYPE seocpdname
        RETURNING
          VALUE(result) TYPE abap_bool,
      find_enclosing_meth_end
        RETURNING
          VALUE(result) TYPE i,
      resolve_target
        IMPORTING
          include TYPE progname
          line    TYPE i.
  PRIVATE SECTION.
    METHODS resolve_by_navigation.
ENDCLASS.

CLASS lcl_class_intfm_src_pos_reader DEFINITION
  INHERITING FROM lcl_intfm_src_pos_reader_base.

  PUBLIC SECTION.
    INTERFACES lif_intfm_source_pos_reader.
    METHODS:
      constructor
        IMPORTING
          full_name       TYPE string
          uri             TYPE string
          method_name     TYPE seocpdname
          source_position TYPE zif_advoat_ty_calh=>ty_source_position
          main_prog       TYPE progname
          include         TYPE progname.
  PROTECTED SECTION.
    METHODS:
      get_sanitized_mainprog_name REDEFINITION.
  PRIVATE SECTION.
    DATA:
      encl_method_start_line TYPE i,
      encl_method_end_line   TYPE i,
      is_main                TYPE xsdboolean,
      classname              TYPE classname.
    METHODS:
      find_enclosing_meth_start.
ENDCLASS.


CLASS lcl_incl_intfm_src_pos_reader DEFINITION
  INHERITING FROM lcl_intfm_src_pos_reader_base.

  PUBLIC SECTION.
    INTERFACES lif_intfm_source_pos_reader.
  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.
