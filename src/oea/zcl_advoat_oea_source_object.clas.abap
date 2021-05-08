"! <p class="shorttext synchronized" lang="en">Source Object for which OEA was triggered</p>
CLASS zcl_advoat_oea_source_object DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_oea_source_object.

    METHODS:
      constructor
        IMPORTING
          name          TYPE sobj_name
          display_name  TYPE sobj_name
          type          TYPE trobjtype
          sub_type      TYPE seu_objtyp
          external_type TYPE trobjtype.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA:
      used_objects  TYPE zif_advoat_oea_used_object=>ty_table,
      env_service   TYPE REF TO zif_advoat_oea_env_service,
      id            TYPE sysuuid_x16,
      parent_ref    TYPE sysuuid_x16,
      external_type TYPE trobjtype,
      type          TYPE trobjtype,
      sub_type      TYPE seu_objtyp,
      name          TYPE sobj_name,
      display_name  TYPE seu_objkey,
      generated     TYPE abap_bool,
      processing    TYPE abap_bool.

    METHODS:
      get_env_service
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_oea_env_service.
ENDCLASS.



CLASS zcl_advoat_oea_source_object IMPLEMENTATION.


  METHOD constructor.
    me->name = name.
    me->display_name = display_name.
    me->external_type = external_type.
    me->sub_type = sub_type.
    me->type = type.
    me->id = zcl_advoat_system_util=>create_sysuuid_x16( ).
  ENDMETHOD.


  METHOD zif_advoat_oea_source_object~persist.
    DATA: used_objects_db TYPE zif_advoat_ty_oea=>ty_used_objects_db.

    LOOP AT used_objects INTO DATA(used_object).
      DATA(used_object_data) = used_object->to_data( ).
      used_object_data-analysis_id = analysis_id.
      used_object_data-source_obj_id = id.
      used_objects_db = VALUE #( BASE used_objects_db ( used_object_data ) ).
    ENDLOOP.

    " discard of duplicates
    SORT used_objects_db BY used_obj_display_name used_obj_type used_obj_sub_type.
    DELETE ADJACENT DUPLICATES FROM used_objects_db COMPARING used_obj_display_name used_obj_type used_obj_sub_type.

    DATA(data_access) = zcl_advoat_oea_dac=>get_instance( ).

    data_access->insert_source_object( VALUE #(
      analysis_id         = analysis_id
      source_obj_id       = id
      generated           = generated
      object_name         = name
      object_display_name = display_name
      object_type         = type
      object_sub_type     = sub_type
      parent_ref          = parent_ref
      used_object_count   = lines( used_objects_db ) ) ).

    data_access->insert_used_objects( used_objects_db ).

  ENDMETHOD.


  METHOD zif_advoat_oea_source_object~determine_environment.
    used_objects = get_env_service( )->determine_used_objects(
      display_name  = CONV #( display_name )
      name          = name
      external_type = external_type ).
  ENDMETHOD.


  METHOD zif_advoat_oea_source_object~set_parent_ref.
    me->parent_ref = parent_ref.
  ENDMETHOD.


  METHOD zif_advoat_oea_source_object~set_id.
    me->id = id.
  ENDMETHOD.


  METHOD zif_advoat_oea_source_object~exists.

    CASE external_type.

      WHEN zif_advoat_c_object_type=>function_module.
        result = zcl_advoat_func_util=>function_exists( CONV #( display_name ) ).

      WHEN zif_advoat_c_tadir_type=>package.
        " TMP packages that start with '$' are not in tadir so a packages will be handled
        " specially
        DATA(packages) = zcl_advoat_reader_factory=>get_package_reader( )->resolve_packages(
          VALUE #( ( sign = 'I' option = 'EQ' low = display_name ) ) ).
        result = xsdbool( lines( packages ) = 1 ).

      WHEN OTHERS.
        DATA(repo_result) = zcl_advoat_reader_factory=>create_repo_reader(
          )->include_by_name( VALUE #( ( name ) )
          )->include_by_type( VALUE #( ( external_type ) )
          )->select_single( ).
        result = xsdbool( repo_result IS NOT INITIAL ).

    ENDCASE.

  ENDMETHOD.


  METHOD zif_advoat_oea_source_object~set_generated.
    me->generated = generated.
  ENDMETHOD.


  METHOD zif_advoat_oea_source_object~needs_processing.
    result = processing.
  ENDMETHOD.


  METHOD zif_advoat_oea_source_object~set_processing.
    me->processing = processing.
  ENDMETHOD.


  METHOD zif_advoat_oea_source_object~get_id.
    result = id.
  ENDMETHOD.


  METHOD zif_advoat_oea_source_object~to_structure.
    result = VALUE zif_advoat_ty_oea=>ty_source_object_ext(
      source_obj_id       = id
      object_type         = type
      object_sub_type     = sub_type
      external_type       = external_type
      object_name         = name
      object_display_name = display_name
      parent_ref          = parent_ref
      generated           = generated
      needs_processing    = processing ).
  ENDMETHOD.


  METHOD zif_advoat_oea_object~get_display_name.
    result = display_name.
  ENDMETHOD.


  METHOD zif_advoat_oea_object~get_name.
    result = name.
  ENDMETHOD.


  METHOD get_env_service.
    IF env_service IS INITIAL.
      env_service = zcl_advoat_oea_env_srv_factory=>create_env_service( external_type ).
    ENDIF.

    result = env_service.
  ENDMETHOD.


ENDCLASS.
