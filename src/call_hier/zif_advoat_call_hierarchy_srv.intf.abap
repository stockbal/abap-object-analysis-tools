"! <p class="shorttext synchronized" lang="en">Call Hierarchy service</p>
INTERFACE zif_advoat_call_hierarchy_srv
  PUBLIC.

  METHODS:
    "! <p class="shorttext synchronized" lang="en">Determines the called units of the given comp. unit</p>
    determine_called_units
      IMPORTING
        comp_unit     TYPE REF TO zif_advoat_compilation_unit
      RETURNING
        VALUE(result) TYPE zif_advoat_compilation_unit=>ty_ref_tab.
ENDINTERFACE.
