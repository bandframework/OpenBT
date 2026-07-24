Examples
========
.. _Branin: https://www.sfu.ca/~ssurjano/branin.html

To use |openbt| in R, install ``Ropenbt`` as described in :doc:`get_started_r`.
This example assumes that the command line tools were built with MPI support.

Let's create a test function. A popular one is the Branin_ function:

.. code-block:: r

    # Test Branin function, rescaled
    braninsc <- function(xx)
    {
      x1 <- xx[1]
      x2 <- xx[2]

      x1bar <- 15*x1 - 5
      x2bar <- 15 * x2

      term1 <- x2bar - 5.1*x1bar^2/(4*pi^2) + 5*x1bar/pi - 6
      term2 <- (10 - 10/(8*pi)) * cos(x1bar)

      y <- (term1^2 + term2 - 44.81) / 51.95
      return(y)
    }


    # Simulate Branin data for testing
    set.seed(99)
    n=500
    p=2
    x = matrix(runif(n*p),ncol=p)
    y=rep(0,n)
    for(i in 1:n) y[i] = braninsc(x[i,])

And then we can load the ``Ropenbt`` package and fit a BART model. Here we set
the model type as ``model="bart"``, which ensures that we fit a homoscedastic BART
model. The number of MPI threads to use is specified as ``tc=4``. For a list
of all optional parameters, see ``args(openbt)``.

.. code-block:: r

    library(Ropenbt)
    fit=openbt(x,y,tc=4,model="bart",modelname="branin")

Next we can construct predictions and make a simple plot. Here, we are
calculating the in-sample predictions since we passed the same ``x`` matrix to
the ``predict.openbt()`` function.

.. code-block:: r

    # Calculate in-sample predictions
    fitp=predict.openbt(fit,x,tc=4)

    # Make a simple plot
    plot(y,fitp$mmean,xlab="observed",ylab="fitted")
    abline(0,1)

To save the model, use the ``openbt.save()`` function. Similarly, load the
model using ``openbt.load()``. Because the posterior can be large in
sample-based models such as these, the fitted model is saved in a compressed
file format with the extension ``.obt``.

.. code-block:: r

    # Save fitted model as test.obt in the working directory
    openbt.save(fit,"test")

    # Load fitted model to a new object.
    fit2=openbt.load("test")

The standard variable activity information, calculated as the proportion of
splitting rules involving each variable, can be computed using the
``vartivity.openbt()`` function.

.. code-block:: r

    # Calculate variable activity information
    fitv=vartivity.openbt(fit2)

    # Plot variable activity
    plot(fitv)

A more accurate alternative is to calculate the Sobol' indices.

.. code-block:: r

    # Calculate Sobol' indices
    fits=sobol.openbt(fit2)
    fits$msi
    fits$mtsi
    fits$msij
