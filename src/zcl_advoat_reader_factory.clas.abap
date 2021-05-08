"! <p class="shorttext synchronized" lang="en">Factory for DDIC Reader classes</p>
CLASS zcl_advoat_reader_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Creates instance of Repository Reader</p>
      create_repo_reader
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_tadir_reader,
      "! <p class="shorttext synchronized" lang="en">Retrieves instance to table reader</p>
      get_table_reader
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_tabl_reader,
      "! <p class="shorttext synchronized" lang="en">Retrieves instance to package reader</p>
      get_package_reader
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_devc_reader.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA:
      package_reader TYPE REF TO zif_advoat_devc_reader,
      table_reader   TYPE REF TO zif_advoat_tabl_reader.
ENDCLASS.



CLASS zcl_advoat_reader_factory IMPLEMENTATION.

  METHOD get_package_reader.
    IF package_reader IS INITIAL.
      package_reader = NEW zcl_advoat_devc_reader( ).
    ENDIF.

    result = package_reader.
  ENDMETHOD.

  METHOD create_repo_reader.
    result = NEW zcl_advoat_tadir_reader( ).
  ENDMETHOD.

  METHOD get_table_reader.
    IF table_reader IS INITIAL.
      table_reader = NEW zcl_advoat_tabl_reader( ).
    ENDIF.

    result = table_reader.
  ENDMETHOD.

ENDCLASS.
