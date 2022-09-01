"! <p class="shorttext synchronized" lang="en">Global constants for Call Hierarchy</p>
INTERFACE zif_advoat_c_calh_global
  PUBLIC.

  CONSTANTS:

    BEGIN OF c_visibility,
      public    TYPE zif_advoat_ty_calh=>ty_visibility VALUE '1',
      protected TYPE zif_advoat_ty_calh=>ty_visibility VALUE '2',
      private   TYPE zif_advoat_ty_calh=>ty_visibility VALUE '3',
    END OF c_visibility,

    BEGIN OF c_class_level,
      instance TYPE zif_advoat_ty_calh=>ty_class_level VALUE '1',
      static   TYPE zif_advoat_ty_calh=>ty_class_level VALUE '2',
    END OF c_class_level.

ENDINTERFACE.
