*&---------------------------------------------------------------------*
*& Report zadvoat_call_tree
*&---------------------------------------------------------------------*
*& Displays a call tree for a given ADT URI
*&---------------------------------------------------------------------*
REPORT zadvoat_call_tree.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT (30) lbl_uri FOR FIELD p_uri.
  PARAMETERS p_uri TYPE string VISIBLE LENGTH 50 DEFAULT '/sap/bc/adt/oo/classes/cl_ris_adt_position_mapping/source/main#start=401,23' LOWER CASE.
SELECTION-SCREEN END OF LINE.

CLASS lcl_call_tree DEFINITION
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING
          uri TYPE string,
      show_call_tree.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_compilation_unit,
        type             TYPE string,
        object_name      TYPE string,
        visibility_icon  TYPE icon_d,
        enclosing_object TYPE string,
        description      TYPE string,
        include          TYPE string,
        line             TYPE i,
        comp_unit_ref    TYPE REF TO zif_advoat_compilation_unit,
        full_name        TYPE string,
      END OF ty_compilation_unit.

    DATA:
      uri               TYPE string,
      compilation_units TYPE STANDARD TABLE OF ty_compilation_unit,
      alv_tree          TYPE REF TO cl_salv_tree.

    METHODS:
      create_tree
        RAISING
          cx_salv_error,
      build_tree,
      display_tree,
      select_initial_data,
      on_expand
        FOR EVENT expand_empty_folder OF cl_salv_events_tree
        IMPORTING
          node_key.
ENDCLASS.


INITIALIZATION.
  lbl_uri = 'ADT URI'.

START-OF-SELECTION.
  NEW lcl_call_tree( p_uri )->show_call_tree( ).




CLASS lcl_call_tree IMPLEMENTATION.

  METHOD constructor.
    me->uri = uri.
  ENDMETHOD.


  METHOD show_call_tree.
    TRY.
        create_tree( ).
      CATCH cx_salv_error.
        RETURN.
    ENDTRY.

    build_tree( ).
    select_initial_data( ).

    display_tree( ).
  ENDMETHOD.


  METHOD create_tree.
    cl_salv_tree=>factory(
      IMPORTING
        r_salv_tree = alv_tree
      CHANGING
        t_table     = compilation_units ).
  ENDMETHOD.


  METHOD build_tree.
    DATA: column TYPE REF TO cl_salv_column_tree.

    DATA(settings) = alv_tree->get_tree_settings( ).
    settings->set_hierarchy_header( 'Method / Form / Function' ).
    settings->set_hierarchy_size( 90 ).

    settings->set_header( 'Call hierarchy' ).

    DATA(columns) = alv_tree->get_columns( ).
    columns->set_optimize( ).

    TRY.
        columns->get_column( columnname = 'OBJECT_NAME' )->set_technical( ).
        columns->get_column( columnname = 'TYPE' )->set_medium_text( 'Type' ).

        column = CAST #( columns->get_column( columnname = 'VISIBILITY_ICON' ) ).
        column->set_short_text( 'Visibil.' ).
        column->set_icon( ).

        columns->get_column( columnname = 'DESCRIPTION' )->set_medium_text( 'Description' ).
        columns->get_column( columnname = 'ENCLOSING_OBJECT' )->set_medium_text( 'Enclosing Object' ).
        columns->get_column( columnname = 'LINE' )->set_medium_text( 'Line' ).
        columns->get_column( columnname = 'INCLUDE' )->set_medium_text( 'Include' ).
        columns->get_column( columnname = 'FULL_NAME' )->set_medium_text( 'Full Name' ).
      CATCH cx_salv_not_found.
    ENDTRY.

    DATA(events) = alv_tree->get_event( ).

    SET HANDLER:
      on_expand FOR events.
  ENDMETHOD.


  METHOD display_tree.
    alv_tree->display( ).
  ENDMETHOD.


  METHOD select_initial_data.
    DATA(comp_unit) = zcl_advoat_call_tree=>get_compilation_unit(
      uri = uri ).

    compilation_units = VALUE #(
      ( object_name      = comp_unit->get_simple_name( )
        type             = comp_unit->get_type( )
        enclosing_object = comp_unit->get_encl_obj_display_name( )
        comp_unit_ref    = comp_unit ) ).

    DATA(nodes) = alv_tree->get_nodes( ).

    TRY.
        DATA(node) = nodes->add_node(
          related_node = space
          relationship = if_salv_c_node_relation=>last_child
          data_row     = compilation_units[ 1 ]
          text         = CONV #( compilation_units[ 1 ]-object_name )
          expander     = abap_true
*         folder       = abap_true
        ).
      CATCH cx_salv_msg.
    ENDTRY.
  ENDMETHOD.


  METHOD on_expand.
    FIELD-SYMBOLS: <comp_unit_row> TYPE ty_compilation_unit.

    cl_progress_indicator=>progress_indicate(
      i_text = 'Determine Call Tree...' ).
    DATA(nodes) = alv_tree->get_nodes( ).

    TRY.
        DATA(comp_unit_row) = nodes->get_node( node_key )->get_data_row( ).
      CATCH cx_salv_msg ##NO_HANDLER.
    ENDTRY.

    ASSIGN comp_unit_row->* TO <comp_unit_row>.

    DATA(called_units) = <comp_unit_row>-comp_unit_ref->get_called_units( ).

    IF called_units IS INITIAL.
      nodes->get_node( node_key )->set_expander( abap_false ).
    ENDIF.

    DATA(related_node) = node_key.
    DATA(relationship) = if_salv_c_node_relation=>last_child.

    LOOP AT called_units INTO DATA(called_unit).
      DATA(call_positions) = called_unit->get_call_positions( ).
      APPEND VALUE #(
          object_name      = called_unit->get_simple_name( )
          type             = called_unit->get_type( )
          enclosing_object = called_unit->get_encl_obj_display_name( )
          comp_unit_ref    = called_unit
          include          = called_unit->get_include( )
          line             = VALUE #( call_positions[ 1 ]-line OPTIONAL )
          full_name        = called_unit->get_full_name( )
          visibility_icon  = SWITCH #( called_unit->get_visibility( )
            WHEN zif_advoat_c_calh_global=>c_visibility-public    THEN icon_led_green
            WHEN zif_advoat_c_calh_global=>c_visibility-protected THEN icon_led_yellow
            WHEN zif_advoat_c_calh_global=>c_visibility-private   THEN icon_led_red )
          description      = called_unit->get_description( )
        ) TO compilation_units ASSIGNING FIELD-SYMBOL(<new_comp_unit>).

      TRY.
          DATA(node) = nodes->add_node(
            related_node = related_node
            relationship = relationship
            data_row     = <new_comp_unit>
            text         = CONV #( <new_comp_unit>-object_name )
            expander     = abap_true ).

          related_node = node->get_key( ).
          relationship = if_salv_c_node_relation=>next_sibling.
        CATCH cx_salv_msg.
      ENDTRY.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
