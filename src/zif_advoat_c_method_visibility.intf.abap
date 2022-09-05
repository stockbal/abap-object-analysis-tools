"! <p class="shorttext synchronized" lang="en">Method visibility</p>
INTERFACE zif_advoat_c_method_visibility
  PUBLIC.

  CONSTANTS:
    public    TYPE zif_advoat_ty_global=>ty_visibility VALUE '1',
    protected TYPE zif_advoat_ty_global=>ty_visibility VALUE '2',
    private   TYPE zif_advoat_ty_global=>ty_visibility VALUE '3'.

ENDINTERFACE.
