CLASS zcl_advoat_system_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Creates x16 UUID</p>
      create_sysuuid_x16
        RETURNING
          VALUE(result) TYPE sysuuid_x16.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_system_util IMPLEMENTATION.

  METHOD create_sysuuid_x16.
    DATA(retry_counter) = 0.
    TRY.
        result = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error INTO DATA(uuid_error).
        CLEAR result.
        IF retry_counter < 3.
          retry_counter = retry_counter + 1.
          RETRY.
        ELSE.
          RAISE EXCEPTION TYPE zcx_advoat_nc_exception
            EXPORTING
              text = uuid_error->get_text( ).
        ENDIF.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
