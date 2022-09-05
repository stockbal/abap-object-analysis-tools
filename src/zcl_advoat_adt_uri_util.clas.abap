"! <p class="shorttext synchronized" lang="en">Utility for ADT URIs</p>
CLASS zcl_advoat_adt_uri_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Retrieves Start position from URI</p>
      get_uri_source_start_pos
        IMPORTING
          uri           TYPE string
        RETURNING
          VALUE(result) TYPE zif_advoat_ty_calh=>ty_source_position.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_adt_uri_util IMPLEMENTATION.

  METHOD get_uri_source_start_pos.
    FIND REGEX '.*#start=(\d+),?(\d+)?.*' IN uri
      RESULTS DATA(match).

    IF lines( match-submatches ) <> 2.
      RETURN.
    ENDIF.

    DATA(line_match) = match-submatches[ 1 ].
    DATA(column_match) = match-submatches[ 2 ].

    IF line_match-offset > 0.
      DATA(offset) = line_match-offset.
      DATA(length) = line_match-length.
      result-line = uri+offset(length).
    ENDIF.

    IF column_match-offset > 0.
      offset = column_match-offset.
      length = column_match-length.
      result-column = uri+offset(length).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
