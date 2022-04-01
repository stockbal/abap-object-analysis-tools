"! <p class="shorttext synchronized" lang="en">Logs Object Environment</p>
CLASS zcl_advoat_oea_analyzer DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_oea_analyzer.

    METHODS:
      "! <p class="shorttext synchronized" lang="en">Create new Analyzer instance</p>
      constructor
        IMPORTING
          description    TYPE string
          source_objects TYPE zif_advoat_ty_global=>ty_tadir_objects.
  PROTECTED SECTION.
    DATA:
      source_objects TYPE zif_advoat_oea_source_object=>ty_table,
      id             TYPE sysuuid_x16.
    METHODS:
      analyze.
  PRIVATE SECTION.
    CONSTANTS:
      c_two_hour_validity TYPE timestamp VALUE 7200.

    DATA:
      tadir_obj_data TYPE zif_advoat_ty_global=>ty_tadir_objects,
      repo_reader    TYPE REF TO zif_advoat_tadir_reader,
      obj_env_dac    TYPE REF TO zif_advoat_oea_dac,
      analysis_info  TYPE zif_advoat_ty_oea=>ty_analysis_info_db.

    METHODS:
      "! <p class="shorttext synchronized" lang="en">Fills analysis information</p>
      fill_analysis_info,
      "! <p class="shorttext synchronized" lang="en">Resolves source object - if needed</p>
      "! Objects of type DEVC cannot be used directly, Instead all objects belonging to the
      "! package are used as source objects,
      resolve_source_objects
        RAISING
          zcx_advoat_exception,
      derive_src_objects
        IMPORTING
          source_object TYPE REF TO zif_advoat_oea_source_object.
ENDCLASS.



CLASS zcl_advoat_oea_analyzer IMPLEMENTATION.


  METHOD constructor.
    tadir_obj_data = tadir_obj_data.
    id = zcl_advoat_system_util=>create_sysuuid_x16( ).
    analysis_info = VALUE #(
      description = description ).
    repo_reader = zcl_advoat_reader_factory=>create_repo_reader( ).
    obj_env_dac = zcl_advoat_oea_dac=>get_instance( ).
    tadir_obj_data = source_objects.
  ENDMETHOD.


  METHOD zif_advoat_oea_analyzer~run.

    DATA(timer) = cl_abap_runtime=>create_hr_timer( ).

    TRY.
        timer->get_runtime( ).
        fill_analysis_info( ).
        resolve_source_objects( ).

        analyze( ).

        GET TIME STAMP FIELD analysis_info-created_at.

        analysis_info-valid_to = cl_abap_tstmp=>add(
          tstmp = analysis_info-created_at
          secs  = c_two_hour_validity ).
        analysis_info-duration = timer->get_runtime( ) / 1000.

        obj_env_dac->insert_analysis_info( analysis_info ).

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

    LOOP AT source_objects INTO DATA(src_obj).
      CHECK src_obj->needs_processing( ).

      src_obj->determine_environment( ).
      src_obj->persist( id ).
      src_obj->set_processing( abap_false ).

      DELETE source_objects.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_advoat_oea_analyzer~get_duration.
    result = analysis_info-duration.
  ENDMETHOD.

ENDCLASS.
