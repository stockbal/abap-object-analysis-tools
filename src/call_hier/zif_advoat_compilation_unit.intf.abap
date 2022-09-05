"! <p class="shorttext synchronized" lang="en">Call hierarchy for a method/form/function</p>
INTERFACE zif_advoat_compilation_unit
  PUBLIC.

  TYPES:
    ty_ref_tab TYPE STANDARD TABLE OF REF TO zif_advoat_compilation_unit WITH EMPTY KEY.

  DATA:
    unit_info TYPE zif_advoat_ty_calh=>ty_compilation_unit READ-ONLY.

  METHODS:
    "! <p class="shorttext synchronized" lang="en">Returns call position URI</p>
    get_call_position_uri
      RETURNING
        VALUE(result) TYPE string,
    "! <p class="shorttext synchronized" lang="en">Retrieves call hierarchy</p>
    get_called_units
      RETURNING
        VALUE(result) TYPE ty_ref_tab.
ENDINTERFACE.
