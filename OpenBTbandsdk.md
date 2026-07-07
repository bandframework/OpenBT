# BAND SDK v0.2 Community Policy Compatibility for OpenBT


> This document summarizes the efforts of current and future BAND member packages to achieve compatibility with the BAND SDK community policies.  Additional details on the BAND SDK are available [here](/resources/sdkpolicies/bandsdk.md) and should be considered when filling out this form. The most recent copy of this template exists [here](/resources/sdkpolicies/template.md).
>
> This file should filled out and placed in the directory in the `bandframework` repository representing the software name appended by `bandsdk`.  For example, if you have a software `foo`, the compatibility file should be named `foobandsdk.md` and placed in the directory housing the software in the `bandframework` repository. No open source code can be included without this file.
>
> All code included in this repository will be open source.  If a piece of code does not contain a open-source LICENSE file as mentioned in the requirements below, then it will be automatically licensed as described in the LICENSE file in the root directory of the bandframework repository.
>
> Please provide information on your compatibility status for each mandatory policy and, if possible, also for recommended policies. If you are not compatible, state what is lacking and what are your plans on how to achieve compliance. For current BAND SDK packages: If you were not fully compatible at some point, please describe the steps you undertook to fulfill the policy. This information will be helpful for future BAND member packages.
>
> To suggest changes to these requirements or obtain more information, please contact [BAND](https://bandframework.github.io/team).
>
> Details on citing the current version of the BAND Framework can be found in the [README](https://github.com/bandframework/bandframework).


**Website:** https://github.com/bandframework/OpenBT \
**Contact:** mpratola@iu.edu, jcyannotty@gmail.com \
**Icon:** https://github.com/bandframework/OpenBT/blob/main/docs/images/openbt_logo_rect.png \
**Description:**  OpenBT implements a variety of Bayesian tree models, including regression, model mixing, sensitivity analysis and multiobjective optimization.  It is built around a C++ codebase along with Python and R interfaces. \

### Mandatory Policies

**BAND SDK**
| # | Policy                 |Support| Notes                   |
|---|-----------------------|-------|-------------------------|
| 1. | Support BAND community GNU Autoconf, CMake, or other build options. |Full| The C++ package is built via Meson, while the Python package can be built and installed using pip.  The R package is installed from within R using the R CRAN "remote" package, which installs directly from the github repo. [M1 details](#m1-details) |
| 2. | Have a README file in the top directory that states a specific set of testing procedures for a user to verify the software was installed and run correctly. |Full| None. [M2 details](#m2-details) |
| 3. | Provide a documented, reliable way to contact the development team. |Full| The OpenBT team can be contacted via the listed author emails or via the public issues page on GitHub. |
| 4. | Come with an open-source license. |Full| Uses the MIT license. |
| 5. | Provide a runtime API to return the current version number of the software. |None| To be included in a future release. |
| 6. | Provide a BAND team-accessible repository. |Full| https://github.com/bandframework/OpenBT |
| 7. | Must allow installing, building, and linking against an outside copy of all imported software that is externally developed and maintained. |Full| The only external dependency for the C++ package is Eigen; the Meson build allows linking to a user-provided Eigen install or will install Eigen itself if none are detected during build. |
| 8. | Have no hardwired print or IO statements that cannot be turned off. |Partial| Building with Meson option verbose=false limits hardwired print statements. |

M1 details <a id="m1-details"></a>: The Meson build system allows one to build a stand-alone install of the base C++ package independent of Python or R.  In principle it can be used directly via the command line interface.  The Python package follows standard Python install procedures with pip pulling information from OpenBT's pypi.org entry.  By default the Python package also builds the base C++ package to facilitate simpler installation for Python users.  The R package requires independent installation of the C++ package first and then R users can directly install the Ropenbt interface from within R.


### Recommended Policies

| # | Policy                 |Support| Notes                   |
|---|------------------------|-------|-------------------------|
|**R1.**| Have a public repository. |Full| OpenBT is a public repository. |
|**R2.**| Free all system resources acquired as soon as they are no longer needed. |Full| None. |
|**R3.**| Provide a mechanism to export ordered list of library dependencies. |None| None. |
|**R4.**| Document versions of packages that it works with or depends upon, preferably in machine-readable form. |None| Python dependencies listed in pyproject.toml; R dependencies listed in NAMESPACE. |
|**R5.**| Have SUPPORT, LICENSE, and CHANGELOG files in top directory.  |Partial| LICENSE file provided. |
|**R6.**| Have sufficient documentation to support use and further development.  |Partial| A readthedocs.io site is provided; some code examples in Examples directory. |
|**R7.**| Be buildable using 64-bit pointers; 32-bit is optional. |Partial| The C++ package is built for 64-bit. |
|**R8.**| Do not assume a full MPI communicator; allow for user-provided MPI communicator. |None| User-provided MPI communicator not currently supported. |
|**R9.**| Use a limited and well-defined name space (e.g., symbol, macro, library, include). |Full| None. |
|**R10.**| Give best effort at portability to key architectures. |Full| The Meson build allows installation on Linux, OS/X and Windows WSL systems. |
|**R11.**| Install headers and libraries under `<prefix>/include` and `<prefix>/lib`, respectively. |Full| None. |
|**R12.**| All BAND compatibility changes should be sustainable. |Full| None. |
|**R13.**| Respect system resources and settings made by other previously called packages. |Full| None. |
|**R14.**| Provide a comprehensive test suite for correctness of installation verification. |Partial| Some rudimentary testing of C++ package on build.  R package has no example testing due to R system's runtime limitation.  To be improved in a future release. |