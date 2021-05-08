*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lcl_parallel_analyzer IMPLEMENTATION.


  METHOD constructor.
    group = group_name.

    DATA(max_group_tasks) = zcl_advoat_parl_proc_utils=>determine_max_tasks( group ).
    IF max_tasks IS INITIAL OR max_tasks > max_group_tasks.
      me->max_tasks = max_group_tasks.
    ELSEIF max_tasks > 0.
      me->max_tasks = max_tasks.
    ELSE.
      me->max_tasks = 1.
    ENDIF.
  ENDMETHOD.


  METHOD run.
    DATA: err_msg TYPE c LENGTH 100,
          free    TYPE i.

    IF initialized = abap_false.
      free_tasks = max_tasks.
      initialized = abap_true.
    ENDIF.

    ASSERT free_tasks > 0.

    ADD 1 TO task_number.
    DATA(task_name) = |{ c_task_name_prefix }{ task_number }|.

    DATA(src_obj_data) = source_object->to_structure( ).
    DO.
      CALL FUNCTION 'ZADVOAT_OEA_PARL_GET_ENV'
        STARTING NEW TASK task_name
        DESTINATION IN GROUP group
        CALLING on_end_of_task ON END OF TASK
        EXPORTING
          analysis_id           = analysis_id
          name                  = src_obj_data-object_name
          display_name          = src_obj_data-object_display_name
          type                  = src_obj_data-object_type
          sub_type              = src_obj_data-object_sub_type
          external_type         = src_obj_data-external_type
        EXCEPTIONS
          system_failure        = 1 MESSAGE err_msg
          communication_failure = 2 MESSAGE err_msg
          resource_failure      = 3
          OTHERS                = 4.
      IF sy-subrc = 3.
        free = free_tasks.
        WAIT UNTIL free_tasks <> free UP TO 1 SECONDS.
        CONTINUE.
      ELSEIF sy-subrc <> 0.
        ASSERT err_msg = '' AND 0 = 1.
      ENDIF.
      EXIT.
    ENDDO.

    free_tasks = free_tasks - 1.

    wait_until_free_task( ).
  ENDMETHOD.


  METHOD on_end_of_task.
    DATA: error_msg TYPE c LENGTH 200.

    RECEIVE RESULTS FROM FUNCTION 'ZADVOAT_OEA_PARL_GET_ENV'
      EXCEPTIONS
        error     = 1
        system_failure = 2 MESSAGE error_msg
        communication_failure = 3 MESSAGE error_msg
        OTHERS = 4.
    IF sy-subrc <> 0.
      " TODO: implement error handling
**      IF NOT mi_log IS INITIAL.
**        IF NOT lv_mess IS INITIAL.
**          mi_log->add_error( lv_mess ).
**        ELSE.
**          mi_log->add_error( |{ sy-msgv1 }{ sy-msgv2 }{ sy-msgv3 }{ sy-msgv3 }, { sy-subrc }| ).
**        ENDIF.
**      ENDIF.
    ENDIF.

    ADD 1 TO free_tasks.
  ENDMETHOD.


  METHOD has_enough_tasks.
    result = xsdbool( max_tasks > 1 ).
  ENDMETHOD.


  METHOD wait_until_finished.
    WAIT UNTIL free_tasks = max_tasks UP TO 120 SECONDS.
  ENDMETHOD.


  METHOD wait_until_free_task.
    WAIT UNTIL free_tasks > 0 UP TO 120 SECONDS.
  ENDMETHOD.


ENDCLASS.
