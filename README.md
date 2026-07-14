# OpenBT
OpenBT is an extensible software project that implements a variety of Bayesian
tree models for scientific and industry applications, including regression,
model mixing, sensitivity analysis and multiobjective optimization.  

The heart of OpenBT is a set of C++ tools that can be used directly via the
command line or indirectly through the `openbt` Python package or `RopenBT` R
package, which wrap the tools.

This repository was established by merging the contents of the original Bitbucket [OpenBT repository](https://bitbucket.org/mpratola/openbt/src/master/) with the [OpenBTMixing repository](https://github.com/jcyannotty/OpenBT), which was based off of the former. It, therefore, supersedes those two repositories, which will be frozen.  Releases resulting from this merging start with `v1.2.0`.

This repository and its contents are being established and developed as part of [BAND framework](https://bandframework.github.io).

### Repository
[![Build Sphinx Docs](https://github.com/bandframework/OpenBT/actions/workflows/build_docs.yml/badge.svg?branch=main)](https://github.com/bandframework/OpenBT/actions/workflows/build_docs.yml)
[![Check Links](https://github.com/bandframework/OpenBT/actions/workflows/check_links.yml/badge.svg?branch=main)](https://github.com/bandframework/OpenBT/actions/workflows/check_links.yml)
[![Check Spelling](https://github.com/bandframework/OpenBT/actions/workflows/check_spelling.yml/badge.svg?branch=main)](https://github.com/bandframework/OpenBT/actions/workflows/check_spelling.yml)


### C++
[![Test OpenBT C++ Command Line Tools](https://github.com/bandframework/OpenBT/actions/workflows/test_CLTs.yml/badge.svg?branch=main)](https://github.com/bandframework/OpenBT/actions/workflows/test_CLTs.yml)

### Python
[![Measure OpenBT Python Coverage](https://github.com/bandframework/OpenBT/actions/workflows/measure_coverage.yml/badge.svg?branch=main)](https://github.com/bandframework/OpenBT/actions/workflows/measure_coverage.yml)
[![Test OpenBT Python Source Distribution](https://github.com/bandframework/OpenBT/actions/workflows/test_py_sdist.yml/badge.svg?branch=main)](https://github.com/bandframework/OpenBT/actions/workflows/test_py_sdist.yml)
[![Test OpenBT Developer-mode Installation](https://github.com/bandframework/OpenBT/actions/workflows/test_py_devmode.yml/badge.svg?branch=main)](https://github.com/bandframework/OpenBT/actions/workflows/test_py_devmode.yml)
[![Test OpenBT in Anaconda](https://github.com/bandframework/OpenBT/actions/workflows/test_anaconda.yml/badge.svg?branch=main)](https://github.com/bandframework/OpenBT/actions/workflows/test_anaconda.yml)

## License & Copyright
Please see [LICENSE](https://github.com/bandframework/OpenBT/blob/main/LICENSE).

## Support
To

* report potential problems with OpenBT or any of the packages derived from it,
* propose a change, or
* request a new feature,

please check if a related [Issue](https://github.com/bandframework/OpenBT/issues)
already exists before creating a new issue.  For all other communication, please
send an email to the OpenBT development team

 * mpratola@iu.edu
 * jcyannotty@gmail.com

## Documentation

[User and Developer Guides](https://openbt.readthedocs.io) are hosted on
ReadTheDocs.  Please refer to those documents for information regarding
examples.

## Installation & Testing
Refer to the getting started sections in the User Guide related to the tool or
package that you intend to use.

## Contributing to OpenBT

Contributions are welcome in a variety of forms; see
[Contributing](https://openbt.readthedocs.io/en/latest/contributing.html) in the
Developer Guide.

## Cite OpenBT

```
@techreport{openbt2026,
  author      = {Matthew Pratola and John Yannotty},
  title       = {{OpenBT 1.2.0} User Guides},
  institution = {Indiana University Bloomington},
  number      = {Version 1.2.0},
  year        = {2026},
  url         = {https://openbt.readthedocs.io/}
}
```
