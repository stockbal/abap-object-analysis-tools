"! <p class="shorttext synchronized" lang="en">Logs Object Environment</p>
CLASS zcl_advoat_oea_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_oea_analyzer.

    METHODS:
      "! <p class="shorttext synchronized" lang="en">Create new Analyzer instance</p>
      constructor
        IMPORTING
          description    TYPE string
          source_objects TYPE zif_advoat_ty_global=>ty_tadir_objects
          parallel       TYPE abap_bool OPTIONAL
          max_tasks      TYPE i DEFAULT 12.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
      c_two_hour_validity TYPE timestamp VALUE 7200.

    DATA:
      id                   TYPE sysuuid_x16,
      tadir_obj_data       TYPE zif_advoat_ty_global=>ty_tadir_objects,
      source_objects_flat  TYPE zif_advoat_ty_oea=>ty_source_objects_ext,
      source_objects       TYPE zif_advoat_oea_source_object=>ty_table,
      parallel             TYPE abap_bool,
      max_tasks            TYPE i,
      repo_reader          TYPE REF TO zif_advoat_tadir_reader,
      obj_env_dac          TYPE REF TO zif_advoat_oea_dac,
      analysis_info        TYPE zif_advoat_ty_oea=>ty_analysis_info_db,
      analyzed_with_errors TYPE abap_bool,
      free_tasks           TYPE i,
      server_group         TYPE rzlli_apcl.

    METHODS:
      "! <p class="shorttext synchronized" lang="en">Fills analysis information</p>
      fill_analysis_info,
      "! <p class="shorttext synchronized" lang="en">Resolves source object - if needed</p>
      "! Objects of type DEVC cannot be used directly, Instead all objects belonging to the
      "! package are used as source objects,
      resolve_source_objects
        RAISING
          zcx_advoat_exception,
      is_parallel_active
        RETURNING
          VALUE(result) TYPE abap_bool,
      run_serial
        IMPORTING
          source_object TYPE REF TO zif_advoat_oea_source_object,
      derive_src_objects
        IMPORTING
          source_object TYPE REF TO zif_advoat_oea_source_object,
      analyze.
ENDCLASS.



CLASS zcl_advoat_oea_analyzer IMPLEMENTATION.


  METHOD constructor.
    tadir_obj_data = tadir_obj_data.
    id = zcl_advoat_system_util=>create_sysuuid_x16( ).
    analysis_info = VALUE #(
      description = description ).
    me->parallel = parallel.
    me->max_tasks = max_tasks.
    repo_reader = zcl_advoat_reader_factory=>create_repo_reader( ).
    obj_env_dac = zcl_advoat_oea_dac=>get_instance( ).
    tadir_obj_data = source_objects.
  ENDMETHOD.


  METHOD zif_advoat_oea_analyzer~run.

    TRY.
        fill_analysis_info( ).
        resolve_source_objects( ).
        analyze( ).

        COMMIT WORK.
      CATCH zcx_advoat_exception INTO DATA(error).
        ROLLBACK WORK.
        RAISE EXCEPTION error.
    ENDTRY.

  ENDMETHOD.


  METHOD zif_advoat_oea_analyzer~get_result.

  ENDMETHOD.


  METHOD fill_analysis_info.
    analysis_info = VALUE zif_advoat_ty_oea=>ty_analysis_info_db(
      BASE analysis_info
      analysis_id = id
      created_by  = sy-uname ).

  ENDMETHOD.


  METHOD resolve_source_objects.
    DATA: derived_source_objects TYPE TABLE OF REF TO zif_advoat_oea_source_object.

    LOOP AT tadir_obj_data INTO DATA(tadir_obj_data_entry).
      TRY.
          DATA(source_obj) = zcl_advoat_oea_factory=>create_source_object(
            name          = tadir_obj_data_entry-name
            external_type = tadir_obj_data_entry-type ).
          IF NOT source_obj->exists( ).
            RAISE EXCEPTION TYPE zcx_advoat_not_exists
              EXPORTING
                text = |Object with name { tadir_obj_data_entry-name } | &&
                       |and type { tadir_obj_data_entry-type } does not exist|.
          ENDIF.
        CATCH zcx_advoat_no_wb_type.
          " source object is not usable, so skip it
          CONTINUE.
      ENDTRY.

      IF tadir_obj_data_entry-type = zif_advoat_c_tadir_type=>package.
        source_obj->set_generated( ).

        derive_src_objects( source_obj ).
        source_obj->persist( id ).
      ELSE.
        source_obj->set_processing( ).
        source_objects = VALUE #( BASE source_objects ( source_obj ) ).
      ENDIF.

    ENDLOOP.

    IF source_objects IS INITIAL.
      RAISE EXCEPTION TYPE zcx_advoat_exception
        EXPORTING
          text = |No Source objects could be resolved|.
    ENDIF.
  ENDMETHOD.


  METHOD derive_src_objects.
    DATA(derived_objects) = repo_reader->reset(
      )->include_by_package(
        packages            = VALUE #( ( source_object->get_display_name( ) ) )
        resolve_subpackages = abap_true
      )->select( ).

    LOOP AT derived_objects ASSIGNING FIELD-SYMBOL(<derived_object>).

      TRY.
          DATA(derived_src_obj) = zcl_advoat_oea_factory=>create_source_object(
            name          = <derived_object>-name
            external_type = <derived_object>-type ).
        CATCH zcx_advoat_no_wb_type
              zcx_advoat_not_exists.
          " source object is not usable, so skip it
          CONTINUE.
      ENDTRY.

      derived_src_obj->set_parent_ref( source_object->get_id( ) ).
      derived_src_obj->set_processing( ).

      source_objects = VALUE #( BASE source_objects ( derived_src_obj ) ).

    ENDLOOP.

  ENDMETHOD.


  METHOD analyze.
    DATA: parallel_runner TYPE REF TO lcl_parallel_analyzer,
          start_time      TYPE timestampl,
          end_time        TYPE timestampl.

    GET TIME STAMP FIELD start_time.

    DATA(is_parallel) = is_parallel_active( ).

    IF is_parallel = abap_true.
      parallel_runner = NEW #( max_tasks = max_tasks ).
      " only continue in parallel mode if system has the capacity
      is_parallel = parallel_runner->has_enough_tasks( ).
    ENDIF.

    LOOP AT source_objects INTO DATA(src_obj).
      CHECK src_obj->needs_processing( ).

      IF is_parallel = abap_true.
        parallel_runner->run(
          analysis_id   = analysis_info-analysis_id
          source_object = src_obj ).
      ELSE.
        run_serial( src_obj ).
      ENDIF.

      DELETE source_objects.
    ENDLOOP.

    IF is_parallel = abap_true AND parallel_runner IS BOUND.
      parallel_runner->wait_until_finished( ).
    ENDIF.

    GET TIME STAMP FIELD end_time.

    GET TIME STAMP FIELD analysis_info-created_at.

    analysis_info-valid_to = cl_abap_tstmp=>add(
      tstmp = analysis_info-created_at
      secs  = c_two_hour_validity ).
    analysis_info-duration = cl_abap_tstmp=>subtract(
      tstmp1 = end_time
      tstmp2 = start_time ).

    obj_env_dac->insert_analysis_info( analysis_info ).

  ENDMETHOD.


  METHOD is_parallel_active.
    result = xsdbool( parallel = abap_true AND lines( source_objects ) > 1 ).
  ENDMETHOD.


  METHOD run_serial.
    source_object->determine_environment( ).
    source_object->persist( id ).
    source_object->set_processing( abap_false ).
  ENDMETHOD.


  METHOD zif_advoat_oea_analyzer~get_duration.
    result = analysis_info-duration.
  ENDMETHOD.


ENDCLASS.
