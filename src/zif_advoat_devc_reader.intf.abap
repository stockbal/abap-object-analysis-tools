"! <p class="shorttext synchronized" lang="en">Access to Packages (DEVC)</p>
INTERFACE zif_advoat_devc_reader
  PUBLIC .
  METHODS:
    "! <p class="shorttext synchronized" lang="en">Resolves full package names from Range Table</p>
    resolve_packages
      IMPORTING
        package_range TYPE zif_advoat_ty_global=>ty_package_name_range
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_global=>ty_package_name_range,
    "! <p class="shorttext synchronized" lang="en">Retrieves sub packages by range</p>
    get_subpackages_by_range
      IMPORTING
        package_range TYPE zif_advoat_ty_global=>ty_package_name_range
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_global=>ty_package_name_range,
    "! <p class="shorttext synchronized" lang="en">Retrieves sub packages by tab</p>
    get_subpackages_by_tab
      IMPORTING
        package_names TYPE zif_advoat_ty_global=>ty_package_names
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_global=>ty_package_name_range,
    "! <p class="shorttext synchronized" lang="en">Retrieves sub packages for top package</p>
    get_subpackages
      IMPORTING
        package_name  TYPE devclass
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_global=>ty_package_name_range.
ENDINTERFACE.
