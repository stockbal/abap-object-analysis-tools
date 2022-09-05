"! <p class="shorttext synchronized" lang="en">Utility for navigation</p>
CLASS zcl_advoat_adt_nav_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS:
      navigate_by_uri
        IMPORTING
          uri                   TYPE string
          source                TYPE string_table OPTIONAL
          VALUE(source_include) TYPE progname OPTIONAL
        RETURNING
          VALUE(target_uri)     TYPE string
        RAISING
          zcx_advoat_exception.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_adt_nav_util IMPLEMENTATION.

  METHOD navigate_by_uri.
    DATA: req            TYPE sadt_rest_request,
          res            TYPE sadt_rest_response,
          source_text    TYPE string_table,
          navigation_obj TYPE sadt_object_reference,
          adt_exception  TYPE sadt_exception,
          langu          TYPE string,
          as_string      TYPE string.

    " 1) determine the source code (MANDATORY)
    IF source IS INITIAL AND
        source_include IS INITIAL.
      RAISE EXCEPTION TYPE zcx_advoat_exception.
    ENDIF.

    IF source IS NOT INITIAL.
      source_text = source.
    ELSE.
      IF source_include+30(2) = 'CP'.
        source_include+30(2) = 'CS'.
      ENDIF.
      READ REPORT source_include INTO source_text.
      IF source_text IS INITIAL.
        RAISE EXCEPTION TYPE zcx_advoat_exception.
      ENDIF.
    ENDIF.

    CONCATENATE LINES OF source_text INTO as_string SEPARATED BY cl_abap_char_utilities=>cr_lf.

    DATA(adt_uri) = `/sap/bc/adt/navigation/target` &&
      |?uri={ cl_http_utility=>escape_url( uri ) }| &&
      `&filter=implementation` &&
      `&filter=matchingStatement`.

    " 2) build the request
    req = VALUE #(
      request_line = VALUE #(
        method = 'POST'
        uri = adt_uri )
      message_body = cl_abap_codepage=>convert_to( source = as_string codepage = 'UTF-8' ignore_cerr = abap_true ) ).

    " 3) Execute ADT request
    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = req
      IMPORTING
        response = res.

    " 4) handle response
    IF res IS NOT INITIAL.
      IF res-status_line-status_code >= cl_rest_status_code=>gc_client_error_bad_request.
        DATA(content_type) = REF #( res-header_fields[ name = if_http_header_fields=>content_type ] OPTIONAL ).
        IF content_type IS NOT INITIAL AND content_type->value = if_rest_media_type=>gc_appl_xml.
          CALL TRANSFORMATION sadt_exception
            SOURCE XML res-message_body
            RESULT exception_data = adt_exception
                   langu          = langu.
          RAISE EXCEPTION TYPE zcx_advoat_exception
            EXPORTING
              text = adt_exception-localized_message.
        ENDIF.
      ELSE.
        CALL TRANSFORMATION sadt_object_reference
          SOURCE XML res-message_body
          RESULT object_reference = navigation_obj.

        target_uri = navigation_obj-uri.
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
