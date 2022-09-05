"! <p class="shorttext synchronized" lang="en">Compilation unit factory</p>
INTERFACE zif_advoat_comp_unit_factory
  PUBLIC.

  METHODS:
    "! <p class="shorttext synchronized" lang="en">Creates compilation unit from data request</p>
    create_comp_unit_from_ext
      IMPORTING
        data_request  TYPE zif_advoat_ty_calh=>ty_ris_data_request
      RETURNING
        VALUE(result) TYPE REF TO zif_advoat_compilation_unit
      RAISING
        zcx_advoat_exception,

    "! <p class="shorttext synchronized" lang="en">Creates compilation unit</p>
    create_comp_unit
      IMPORTING
        unit_data     TYPE zif_advoat_ty_calh=>ty_compilation_unit
      RETURNING
        VALUE(result) TYPE REF TO zif_advoat_compilation_unit
      RAISING
        zcx_advoat_exception.
ENDINTERFACE.
