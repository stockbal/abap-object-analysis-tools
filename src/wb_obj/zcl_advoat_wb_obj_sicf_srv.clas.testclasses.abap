*"* use this source file for your ABAP unit test classes
CLASS lcl_abap_unit DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      test_get_wb_object FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS lcl_abap_unit IMPLEMENTATION.

  METHOD test_get_wb_object.
    TRY.
        DATA(cut) = NEW zcl_advoat_wb_obj_sicf_srv( ).
        DATA(wb_obj) = cut->zif_advoat_wb_obj_service~get_wb_object(
            display_name  = '/sap/bc/'
            external_type = 'SICF' ).

        cl_abap_unit_assert=>assert_equals(
          exp = 'BC             DFFAEATGKMFLCDXQ04F0J7FXK'
          act = wb_obj-name ).
        cl_abap_unit_assert=>assert_equals(
          exp = '/sap/bc/'
          act = wb_obj-display_name ).
        cl_abap_unit_assert=>assert_equals(
          exp = 'SICF'
          act = wb_obj-type ).
      CATCH zcx_advoat_not_exists.
      CATCH zcx_advoat_no_wb_type.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
