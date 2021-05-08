"! <p class="shorttext synchronized" lang="en">Object types in TADIR</p>
INTERFACE zif_advoat_c_tadir_type
  PUBLIC .

  CONSTANTS:
    table             TYPE trobjtype VALUE 'TABL' ##NO_TEXT,
    table_type        TYPE trobjtype VALUE 'TTYP' ##NO_TEXT,
    function_group    TYPE trobjtype VALUE 'FUGR' ##NO_TEXT,
    program           TYPE trobjtype VALUE 'PROG' ##NO_TEXT,
    package           TYPE trobjtype VALUE 'DEVC' ##NO_TEXT,
    business_object   TYPE trobjtype VALUE 'BOBF' ##NO_TEXT,
    class             TYPE trobjtype VALUE 'CLAS' ##NO_TEXT,
    interface         TYPE trobjtype VALUE 'INTF' ##NO_TEXT,
    icf_node          TYPE trobjtype VALUE 'SICF' ##NO_TEXT,
    gw_project        TYPE trobjtype VALUE 'IWPR' ##NO_TEXT,
    data_definition   TYPE trobjtype VALUE 'DDLS' ##NO_TEXT,
    structured_object TYPE trobjtype VALUE 'STOB' ##NO_TEXT.
ENDINTERFACE.
