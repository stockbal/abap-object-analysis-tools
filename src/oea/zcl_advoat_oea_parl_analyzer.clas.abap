"! <p class="shorttext synchronized" lang="en">Parallel Object Env. Analysis</p>
CLASS zcl_advoat_oea_parl_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM zcl_advoat_oea_analyzer.

  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING
          description    TYPE string
          source_objects TYPE zif_advoat_ty_global=>ty_tadir_objects
          task_runner    TYPE REF TO zif_advoat_parl_task_runner.
  PROTECTED SECTION.
    METHODS:
      analyze REDEFINITION.
  PRIVATE SECTION.
    DATA:
      task_runner TYPE REF TO zif_advoat_parl_task_runner.
ENDCLASS.



CLASS zcl_advoat_oea_parl_analyzer IMPLEMENTATION.

  METHOD constructor.
    super->constructor(
      description    = description
      source_objects = source_objects ).
    me->task_runner = task_runner.
  ENDMETHOD.


  METHOD analyze.

    LOOP AT source_objects INTO DATA(src_obj).
      CHECK src_obj->needs_processing( ).

      DATA(src_obj_flat) = src_obj->to_structure( ).
      task_runner->run( VALUE zif_advoat_ty_oea=>ty_oea_parl_input(
        analysis_id   = id
        name          = src_obj_flat-object_name
        display_name  = src_obj_flat-object_display_name
        type          = src_obj_flat-object_type
        sub_type      = src_obj_flat-object_sub_type
        external_type = src_obj_flat-external_type ) ).

      DELETE source_objects.
    ENDLOOP.

    task_runner->wait_until_finished( ).

  ENDMETHOD.

ENDCLASS.
