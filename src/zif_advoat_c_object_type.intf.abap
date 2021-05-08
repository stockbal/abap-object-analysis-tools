"! <p class="shorttext synchronized" lang="en">Object type in workbench</p>
INTERFACE zif_advoat_c_object_type
  PUBLIC .

  CONSTANTS:
    structure       TYPE seu_obj VALUE 'STRU' ##NO_TEXT,
    include         TYPE seu_obj VALUE 'INCL' ##NO_TEXT,
    single_message  TYPE seu_obj VALUE 'MESS' ##NO_TEXT,
    function_module TYPE seu_obj VALUE 'FUNC' ##NO_TEXT.
ENDINTERFACE.
