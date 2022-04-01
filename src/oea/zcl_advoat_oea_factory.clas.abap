"! <p class="shorttext synchronized" lang="en">API for Object Environment Analysis</p>
CLASS zcl_advoat_oea_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Create new Object Environment Analyzer</p>
      create_analyzer
        IMPORTING
          description    TYPE string OPTIONAL
          source_objects TYPE zif_advoat_ty_global=>ty_tadir_objects
          parallel       TYPE abap_bool OPTIONAL
          server_group   TYPE rzlli_apcl OPTIONAL
        RETURNING
          VALUE(result)  TYPE REF TO zif_advoat_oea_analyzer,
      "! <p class="shorttext synchronized" lang="en">Creates new used object instance</p>
      create_used_object
        IMPORTING
          name               TYPE seu_objkey
          external_type      TYPE trobjtype
          enclosing_obj_name TYPE seu_objkey OPTIONAL
        RETURNING
          VALUE(result)      TYPE REF TO zif_advoat_oea_used_object,
      "! <p class="shorttext synchronized" lang="en">Creates new source object instance</p>
      create_source_object
        IMPORTING
          name          TYPE sobj_name
          external_type TYPE trobjtype
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_oea_source_object
        RAISING
          zcx_advoat_no_wb_type
          zcx_advoat_not_exists,
      "! <p class="shorttext synchronized" lang="en">Creates fully defined source object</p>
      create_source_object_no_check
        IMPORTING
          name          TYPE sobj_name
          display_name  TYPE sobj_name
          type          TYPE trobjtype
          sub_type      TYPE seu_objtyp
          external_type TYPE trobjtype
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_oea_source_object,

      "! <p class="shorttext synchronized" lang="en">Determines object environment (for ARFC call)</p>
      determine_object_env_arfc
        IMPORTING
          input  TYPE zif_advoat_ty_oea=>ty_oea_parl_input
        EXPORTING
          output TYPE sy-subrc.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_oea_factory IMPLEMENTATION.


  METHOD create_analyzer.
    DATA: task_runner TYPE REF TO zif_advoat_parl_task_runner.

    IF parallel = abap_true.
      TRY.
          task_runner = zcl_advoat_parl_task_runner=>new(
            server_group   = server_group
            max_tasks      = 12
            handler_class  = 'ZCL_ADVOAT_OEA_FACTORY'
            handler_method = 'DETERMINE_OBJECT_ENV_ARFC' ).
        CATCH zcx_advoat_exception INTO DATA(error) ##needed.
          " TODO: collect error into log
      ENDTRY.
    ENDIF.

    result = COND #(
      WHEN task_runner IS BOUND THEN
        NEW zcl_advoat_oea_parl_analyzer(
          description    = description
          source_objects = source_objects
          task_runner = task_runner )
      ELSE
        NEW zcl_advoat_oea_analyzer(
          description    = description
          source_objects = source_objects ) ).
  ENDMETHOD.


  METHOD create_source_object.
    DATA(wb_object) = zcl_advoat_wb_obj_srv_factory=>get_service( external_type )->get_wb_object(
      display_name  = name
      external_type = external_type ).

    result = NEW zcl_advoat_oea_source_object(
      name          = wb_object-name
      display_name  = wb_object-display_name
      type          = wb_object-type
      sub_type      = wb_object-sub_type
      external_type = external_type ).
  ENDMETHOD.


  METHOD create_source_object_no_check.
    result = NEW zcl_advoat_oea_source_object(
      name          = name
      display_name  = display_name
      type          = type
      sub_type      = sub_type
      external_type = external_type ).
  ENDMETHOD.


  METHOD create_used_object.
    TRY.
        DATA(wb_object) = zcl_advoat_wb_obj_srv_factory=>get_service( external_type )->get_wb_object(
          display_name  = CONV #( name )
          external_type = external_type ).
      CATCH zcx_advoat_not_exists
            zcx_advoat_no_wb_type ##NO_HANDLER.
    ENDTRY.

    result = NEW zcl_advoat_oea_used_object(
      name         = CONV #( wb_object-name )
      display_name = CONV #( wb_object-display_name )
      type         = wb_object-type
      sub_type     = wb_object-sub_type ).
  ENDMETHOD.


  METHOD determine_object_env_arfc.
    zcl_advoat_parl_proc_utils=>assert_async_rfc_call( ).

    DATA(source_object) = create_source_object_no_check(
      name          = input-name
      display_name  = input-display_name
      type          = input-type
      sub_type      = input-sub_type
      external_type = input-external_type ).
    source_object->determine_environment( ).
    source_object->persist( input-analysis_id ).

    output = 0.

  ENDMETHOD.

ENDCLASS.
