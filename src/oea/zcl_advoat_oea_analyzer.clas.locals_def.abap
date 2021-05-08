*"* use this source file for any type of declarations (class
*"* definitions, interfaces or type declarations) you need for
*"* components in the private section
CLASS lcl_parallel_analyzer DEFINITION.

  PUBLIC SECTION.
    METHODS:
      "! Creates new parallel processor
      constructor
        IMPORTING
          group_name TYPE rzlli_apcl OPTIONAL
          max_tasks  TYPE i OPTIONAL,
      "! Returns 'X' if there are enough tasks
      has_enough_tasks
        RETURNING
          VALUE(result) TYPE abap_bool,
      "! Runs parallel environment analysis
      run
        IMPORTING
          analysis_id   TYPE sysuuid_x16
          source_object TYPE REF TO zif_advoat_oea_source_object,
      wait_until_free_task,
      wait_until_finished,
      on_end_of_task
        IMPORTING
          p_task TYPE clike.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
      c_task_name_prefix TYPE string VALUE 'ENVANALYSIS:'.

    DATA:
      task_number TYPE i,
      free_tasks  TYPE i,
      group       TYPE rzlli_apcl,
      max_tasks   TYPE i,
      initialized TYPE abap_bool.
ENDCLASS.
