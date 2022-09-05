"! <p class="shorttext synchronized" lang="en">Wrapper around ABAP Compiler</p>
INTERFACE zif_advoat_abap_compiler
  PUBLIC.

  METHODS:
    "! <p class="shorttext synchronized" lang="en">Retrieves compilation unit src info by begin/end refs</p>
    get_src_by_start_end_refs
      IMPORTING
        full_name     TYPE string
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_calh=>ty_cu_src_info,

    "! <p class="shorttext synchronized" lang="en">Retrieves refs for single fullname</p>
    get_refs_by_fullname
      IMPORTING
        full_name     TYPE string
        grade         TYPE scr_grade OPTIONAL
      RETURNING
        VALUE(result) TYPE scr_refs,

    "! <p class="shorttext synchronized" lang="en">Retrieve refs for list of fullnames</p>
    get_refs_by_fullnames
      IMPORTING
        full_names    TYPE scr_names_grades
      RETURNING
        VALUE(result) TYPE scr_refs,

    "! <p class="shorttext synchronized" lang="en">Check a Full Name (Existence of Object)</p>
    get_symbol_entry
      IMPORTING
        full_name     TYPE string
      RETURNING
        VALUE(result) TYPE REF TO cl_abap_comp_symbol,

    "! <p class="shorttext synchronized" lang="en">Retrieve references in given include and range</p>
    get_refs_in_range
      IMPORTING
        include       TYPE progname
        start_line    TYPE i
        end_line      TYPE i
      RETURNING
        VALUE(result) TYPE scr_names_tags_grades,

    "! <p class="shorttext synchronized" lang="en">Retrieves direct references in range</p>
    get_direct_references
      IMPORTING
        include       TYPE progname
        full_name     TYPE string
        start_line    TYPE i
        end_line      TYPE i
      RETURNING
        VALUE(result) TYPE scr_refs,

    "! <p class="shorttext synchronized" lang="en">Retrieve fullname in include for the given position</p>
    get_full_name_for_position
      IMPORTING
        include       TYPE progname
        line          TYPE i
        column        TYPE i
      RETURNING
        VALUE(result) TYPE  scr_name_tag_grade .

ENDINTERFACE.
