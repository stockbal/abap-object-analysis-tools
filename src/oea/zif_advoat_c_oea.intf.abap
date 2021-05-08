"! <p class="shorttext synchronized" lang="en">Constants for object environment analysis</p>
INTERFACE zif_advoat_c_oea
  PUBLIC .

  CONSTANTS:
    "! <p class="shorttext synchronized" lang="en">Aggregation level for object environment</p>
    BEGIN OF c_aggregation_level,
      by_type           TYPE zif_advoat_ty_oea=>ty_aggregation_level VALUE '1',
      by_calling_object TYPE zif_advoat_ty_oea=>ty_aggregation_level VALUE '2',
    END OF c_aggregation_level.

  CONSTANTS:
    "! <p class="shorttext synchronized" lang="en">Mode for object environment analysis</p>
    BEGIN OF c_analysis_mode,
      "! Analysis of used objects
      by_object  TYPE zif_advoat_ty_oea=>ty_analysis_mode VALUE '1',
      "! Analysis results are aggregated to get an overview which packages a given
      "! package is using <br/>
      "! This is useful to detect any package violations
      by_package TYPE zif_advoat_ty_oea=>ty_analysis_mode VALUE '2',
    END OF c_analysis_mode.
ENDINTERFACE.
