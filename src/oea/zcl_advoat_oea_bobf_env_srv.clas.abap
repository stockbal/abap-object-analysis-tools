"! <p class="shorttext synchronized" lang="en">Environment determination for BOBF objects</p>
CLASS zcl_advoat_oea_bobf_env_srv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES:
      zif_advoat_oea_env_service.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_used_obj_external,
        external_type TYPE trobjtype,
        name          TYPE seu_objkey,
      END OF ty_used_obj_external,

      ty_used_objects_external TYPE TABLE OF ty_used_obj_external,

      BEGIN OF ty_bo_properties,
        const_interface            TYPE /bobf/obm_obj-const_interface,
        object_model_cds_view_name TYPE c LENGTH 30,
      END OF ty_bo_properties,

      BEGIN OF ty_bo_node,
        data_type                     TYPE /bobf/obm_node-data_type,
        data_data_type                TYPE /bobf/obm_node-data_data_type,
        data_table_type               TYPE /bobf/obm_node-data_table_type,
        database_table                TYPE /bobf/obm_node-database_table,
        auth_check_class              TYPE /bobf/obm_node-auth_check_class,
        object_model_cds_view_name    TYPE c LENGTH 30,
        object_mdl_active_persistence TYPE tabname,
        draft_class                   TYPE classname,
        draft_data_type               TYPE tabname,
        object_mdl_draft_persistence  TYPE tabname,
      END OF ty_bo_node.

    METHODS:
      find_bo_properties
        IMPORTING
          !bo_name      TYPE /bobf/obm_name
        CHANGING
          !used_objects TYPE ty_used_objects_external,
      find_actions
        IMPORTING
          !bo_name      TYPE /bobf/obm_name
        CHANGING
          !used_objects TYPE ty_used_objects_external,
      find_determinatations
        IMPORTING
          !bo_name      TYPE /bobf/obm_name
        CHANGING
          !used_objects TYPE ty_used_objects_external,
      find_validations
        IMPORTING
          !bo_name      TYPE /bobf/obm_name
        CHANGING
          !used_objects TYPE ty_used_objects_external,
      find_nodes
        IMPORTING
          !bo_name      TYPE /bobf/obm_name
        CHANGING
          !used_objects TYPE ty_used_objects_external,
      find_alt_keys
        IMPORTING
          !bo_name      TYPE /bobf/obm_name
        CHANGING
          !used_objects TYPE ty_used_objects_external.
ENDCLASS.



CLASS zcl_advoat_oea_bobf_env_srv IMPLEMENTATION.


  METHOD find_actions.
    SELECT act_class,
           param_data_type,
           export_param_s,
           export_param_tt
      FROM /bobf/act_list
      WHERE name = @bo_name
        AND act_class <> ''
      INTO TABLE @DATA(bo_actions).

    LOOP AT bo_actions ASSIGNING FIELD-SYMBOL(<action>).
      used_objects = VALUE #( BASE used_objects
        ( name = <action>-act_class        external_type = zif_advoat_c_tadir_type=>class )
        ( name = <action>-param_data_type  external_type = zif_advoat_c_object_type=>structure )
        ( name = <action>-export_param_s   external_type = zif_advoat_c_object_type=>structure )
        ( name = <action>-export_param_tt  external_type = zif_advoat_c_tadir_type=>table_type ) ).
    ENDLOOP.

  ENDMETHOD.


  METHOD find_alt_keys.
    SELECT data_type,
           data_table_type
      FROM /bobf/obm_altkey
      WHERE name = @bo_name
      INTO TABLE @DATA(bo_alt_keys).

    LOOP AT bo_alt_keys ASSIGNING FIELD-SYMBOL(<alt_key>).
      used_objects = VALUE #( BASE used_objects
        ( name = <alt_key>-data_type       external_type = zif_advoat_c_object_type=>structure )
        ( name = <alt_key>-data_table_type external_type = zif_advoat_c_tadir_type=>table_type ) ).
    ENDLOOP.

  ENDMETHOD.


  METHOD find_bo_properties.
    DATA bo_properties TYPE ty_bo_properties.

    " 1) Select properties for NW >= 740
    SELECT SINGLE const_interface
      FROM /bobf/obm_obj
      WHERE name = @bo_name
      INTO CORRESPONDING FIELDS OF @bo_properties.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " 2) Try to select properties for NW > 740
    DATA(select_list) = `object_model_cds_view_name`.
    TRY.
        SELECT SINGLE (select_list)
          FROM /bobf/obm_obj
          WHERE name = @bo_name
          INTO CORRESPONDING FIELDS OF @bo_properties.
      CATCH cx_sy_dynamic_osql_semantics ##NO_HANDLER.
    ENDTRY.

    used_objects = VALUE #( BASE used_objects
     ( name = bo_properties-const_interface            external_type = zif_advoat_c_tadir_type=>interface )
     ( name = bo_properties-object_model_cds_view_name external_type = zif_advoat_c_tadir_type=>structured_object ) ).
  ENDMETHOD.


  METHOD find_determinatations.
    SELECT det_class
      FROM /bobf/det_list
      WHERE name = @bo_name
        AND det_class <> ''
      INTO TABLE @DATA(bo_determinations).

    LOOP AT bo_determinations ASSIGNING FIELD-SYMBOL(<determination>).
      APPEND VALUE #(
        name          = <determination>-det_class
        external_type = zif_advoat_c_tadir_type=>class ) TO used_objects.
    ENDLOOP.

  ENDMETHOD.


  METHOD find_nodes.
    DATA: bo_nodes TYPE TABLE OF ty_bo_node.
    FIELD-SYMBOLS: <node> TYPE zcl_advoat_oea_bobf_env_srv=>ty_bo_node.

    " 1) Select properties for NW >= 740
    SELECT node~data_type,
           node~data_data_type,
           node~data_table_type,
           node~database_table,
           node~auth_check_class
      FROM /bobf/obm_bo AS bo
        INNER JOIN /bobf/obm_node AS node
          ON bo~bo_key = node~bo_key
      WHERE bo~bo_name = @bo_name
      INTO CORRESPONDING FIELDS OF TABLE @bo_nodes.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT bo_nodes ASSIGNING <node>.
      used_objects = VALUE #( BASE used_objects
        ( name = <node>-data_type                      external_type = zif_advoat_c_object_type=>structure )
        ( name = <node>-data_data_type                 external_type = zif_advoat_c_object_type=>structure )
        ( name = <node>-data_table_type                external_type = zif_advoat_c_tadir_type=>table_type )
        ( name = <node>-database_table                 external_type = zif_advoat_c_tadir_type=>table )
        ( name = <node>-auth_check_class               external_type = zif_advoat_c_tadir_type=>class ) ).
    ENDLOOP.

    " 2) Try to select properties for NW > 740
    DATA(select_list) = `node~object_model_cds_view_name, ` && |\r\n| &&
                        `mode~object_mdl_active_persistence, ` && |\r\n| &&
                        `mode~draft_class, ` && |\r\n| &&
                        `mode~draft_data_type, ` && |\r\n| &&
                        `mode~object_mdl_active_persistence`.
    TRY.
        SELECT (select_list)
          FROM /bobf/obm_bo AS bo
            INNER JOIN /bobf/obm_node AS node
              ON bo~bo_key = node~bo_key
          WHERE bo~bo_name = @bo_name
          INTO CORRESPONDING FIELDS OF TABLE @bo_nodes.
      CATCH cx_sy_dynamic_osql_semantics ##NO_HANDLER.
        RETURN.
    ENDTRY.

    LOOP AT bo_nodes ASSIGNING <node>.
      used_objects = VALUE #( BASE used_objects
        ( name = <node>-object_model_cds_view_name     external_type = zif_advoat_c_tadir_type=>structured_object )
        ( name = <node>-object_mdl_active_persistence  external_type = zif_advoat_c_tadir_type=>table )
        ( name = <node>-draft_class                    external_type = zif_advoat_c_tadir_type=>class )
        ( name = <node>-draft_data_type                external_type = zif_advoat_c_object_type=>structure )
        ( name = <node>-object_mdl_draft_persistence   external_type = zif_advoat_c_tadir_type=>table ) ).
    ENDLOOP.
  ENDMETHOD.


  METHOD find_validations.
    SELECT val_class
      FROM /bobf/val_list
      WHERE name = @bo_name
        AND val_class <> ''
      INTO TABLE @DATA(bo_validations).

    LOOP AT bo_validations ASSIGNING FIELD-SYMBOL(<validation>).
      APPEND VALUE #(
        name          = <validation>-val_class
        external_type = zif_advoat_c_tadir_type=>class ) TO used_objects.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_advoat_oea_env_service~determine_used_objects.
    DATA: used_objects_data TYPE ty_used_objects_external.

    DATA(bo_name) = CONV /bobf/obm_name( name ).

    find_bo_properties(
      EXPORTING bo_name = bo_name
      CHANGING  used_objects = used_objects_data ).
    find_actions(
      EXPORTING bo_name = bo_name
      CHANGING  used_objects = used_objects_data ).
    find_determinatations(
      EXPORTING bo_name = bo_name
      CHANGING used_objects = used_objects_data ).
    find_validations(
      EXPORTING bo_name = bo_name
      CHANGING used_objects = used_objects_data ).
    find_nodes(
      EXPORTING bo_name = bo_name
      CHANGING used_objects = used_objects_data ).
    find_alt_keys(
      EXPORTING bo_name = bo_name
      CHANGING used_objects = used_objects_data ).

    SORT used_objects_data.
    DELETE ADJACENT DUPLICATES FROM used_objects_data.

    LOOP AT used_objects_data ASSIGNING FIELD-SYMBOL(<used_obj_data>) WHERE name IS NOT INITIAL.
      APPEND zcl_advoat_oea_factory=>create_used_object(
        name          = <used_obj_data>-name
        external_type = <used_obj_data>-external_type ) TO result.
    ENDLOOP.

  ENDMETHOD.


ENDCLASS.
