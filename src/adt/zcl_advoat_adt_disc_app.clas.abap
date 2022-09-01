"! <p class="shorttext synchronized" lang="en">Router for ABAP Object Analysis Tools</p>
CLASS zcl_advoat_adt_disc_app DEFINITION
  PUBLIC
  INHERITING FROM cl_adt_disc_res_app_base
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS
      class_constructor.

    METHODS:
      if_adt_rest_rfc_application~get_static_uri_path REDEFINITION.
  PROTECTED SECTION.
    METHODS:
      fill_router REDEFINITION,
      get_application_title REDEFINITION,
      register_resources REDEFINITION.
  PRIVATE SECTION.
    CONSTANTS:
      c_static_uri                TYPE string VALUE '/devepos/adt/oat',
      c_root_scheme               TYPE string VALUE 'http://www.devepos.com/adt/oat',
      c_root_rel_scheme           TYPE string VALUE 'http://www.devepos.com/adt/relations/oat'.
ENDCLASS.



CLASS zcl_advoat_adt_disc_app IMPLEMENTATION.

  METHOD class_constructor.
  ENDMETHOD.


  METHOD if_adt_rest_rfc_application~get_static_uri_path.
    result = c_static_uri.
  ENDMETHOD.


  METHOD fill_router.
    super->fill_router( CHANGING router = router ).
    router->attach(
      iv_template      = '/discovery'
      iv_handler_class = cl_adt_res_discovery=>co_class_name ).
  ENDMETHOD.


  METHOD get_application_title.
    result = 'ABAP Object Analysis Tools'.
  ENDMETHOD.


  method register_resources.
  ENDMETHOD.

ENDCLASS.
