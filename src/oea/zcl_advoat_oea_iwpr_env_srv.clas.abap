"! <p class="shorttext synchronized" lang="en">Environment determination for SEGW Projects</p>
CLASS zcl_advoat_oea_iwpr_env_srv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_oea_env_service .
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
      c_sadl_model_exp_data_intf TYPE string VALUE 'IF_SADL_GW_MODEL_EXPOSURE_DATA'.
    TYPES:
      BEGIN OF ty_generated_obj,
        tadir_type   TYPE trobjtype,
        tadir_name   TYPE sobj_name,
        gen_obj_type TYPE /iwbep/sbdm_gen_art_type,
      END OF ty_generated_obj,
      ty_generated_objs TYPE STANDARD TABLE OF ty_generated_obj WITH EMPTY KEY.

    METHODS:
      read_generated_objects
        IMPORTING
          segw_project  TYPE /iwbep/sbdm_project
        RETURNING
          VALUE(result) TYPE ty_generated_objs,
      add_generated_objects
        IMPORTING
          generated_objects TYPE ty_generated_objs
        CHANGING
          used_objects      TYPE zif_advoat_oea_used_object=>ty_table,
      add_sadl_objects
        IMPORTING
          mpc_name     TYPE sobj_name
        CHANGING
          used_objects TYPE zif_advoat_oea_used_object=>ty_table.
ENDCLASS.


CLASS zcl_advoat_oea_iwpr_env_srv IMPLEMENTATION.

  METHOD zif_advoat_oea_env_service~determine_used_objects.
    DATA(generated_objects) = read_generated_objects( CONV #( name ) ).
    IF generated_objects IS NOT INITIAL.
      add_generated_objects(
        EXPORTING generated_objects = generated_objects
        CHANGING  used_objects      = result ).

      ASSIGN generated_objects[ gen_obj_type = 'MPCB' ] TO FIELD-SYMBOL(<mpc>).
      IF sy-subrc = 0.
        add_sadl_objects(
          EXPORTING mpc_name     = <mpc>-tadir_name
          CHANGING  used_objects = result ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD read_generated_objects.
    SELECT trobj_type AS tadir_type,
           trobj_name AS tadir_name,
           gen_art_type AS gen_obj_type
      FROM /iwbep/i_sbd_ga
      WHERE project = @segw_project
        AND ( trobj_type = @zif_advoat_c_tadir_type=>class OR
              trobj_type = @zif_advoat_c_tadir_type=>interface )
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD add_generated_objects.

    LOOP AT generated_objects ASSIGNING FIELD-SYMBOL(<generated_object>).
      APPEND zcl_advoat_oea_factory=>create_used_object(
        name          = CONV #( <generated_object>-tadir_name )
        external_type = <generated_object>-tadir_type ) TO used_objects.
    ENDLOOP.

  ENDMETHOD.


  METHOD add_sadl_objects.
    DATA: mpc             TYPE REF TO object,
          model_exposure  TYPE REF TO object,
          model_provider  TYPE REF TO object,
          sadl_definition TYPE if_sadl_types=>ty_sadl_definition.

    cl_abap_typedescr=>describe_by_name(
      EXPORTING  p_name         = mpc_name
      RECEIVING  p_descr_ref    = DATA(type_descr)
      EXCEPTIONS type_not_found = 1 ).
    IF sy-subrc <> 0 OR type_descr->kind <> cl_abap_typedescr=>kind_class.
      RETURN.
    ENDIF.

    DATA(mpc_cls_descr) = CAST cl_abap_classdescr( type_descr ).

    IF NOT line_exists( mpc_cls_descr->interfaces[ name = c_sadl_model_exp_data_intf ] ).
      RETURN.
    ENDIF.

    TRY.
        CREATE OBJECT mpc TYPE (mpc_name).

        CALL METHOD mpc->('IF_SADL_GW_MODEL_EXPOSURE_DATA~GET_MODEL_EXPOSURE')
          RECEIVING
            ro_model_exposure = model_exposure.

        CALL METHOD model_exposure->('GET_MP')
          RECEIVING
            ro_mp = model_provider.

        CALL METHOD model_provider->('IF_BSA_SADL_MP~GET_SADL_DEFINITION')
          RECEIVING
            rs_sadl_definition = sadl_definition.
      CATCH cx_sy_create_object_error
            cx_sy_ref_is_initial
            cx_sy_dyn_call_error.
        RETURN.
    ENDTRY.


    LOOP AT sadl_definition-data_sources ASSIGNING FIELD-SYMBOL(<data_source>) WHERE type = 'CDS'.
      APPEND zcl_advoat_oea_factory=>create_used_object(
        name          = CONV #( <data_source>-name )
        external_type = zif_advoat_c_tadir_type=>data_definition ) TO used_objects.
    ENDLOOP.
  ENDMETHOD.


ENDCLASS.
