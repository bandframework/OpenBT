# OpenBT
OpenBT is an extensible software project that implements a variety of Bayesian
tree models for scientific and industry applications, including regression,
model mixing, sensitivity analysis and multiobjective optimization.  

The heart of OpenBT is a set of C++ tools that can be used directly _via_ the
command line or indirectly through the `openbt` Python package or `RopenBT` R
package, which wrap the tools.

The introduction of a Python wrapper in the OpenBT project was started in this PyPI project space as the `openbt` package.  These efforts were later expanded independently in the [OpenBTMixing project](https://github.com/jcyannotty/OpenBT), which was based off of the original Bitbucket [OpenBT project](https://bitbucket.org/mpratola/openbt/src/master/), and its [openbtmixing package](https://pypi.org/project/openbtmixing/).  These two projects were [merged together](https://github.com/bandframework/OpenBT) with the resulting, modernized Python package being distributed here as the `openbt` package as of `v1.2.0`.

This repository and its contents are being established and developed as part of [BAND framework](https://bandframework.github.io).

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
  author      = {Matt Pratola and John Yannotty},
  title       = {{OpenBT 1.2.0} User Guides},
  institution = {TBD},
  number      = {Version 1.2.0},
  year        = {2026},
  url         = {https://openbt.readthedocs.io/}
}
```
