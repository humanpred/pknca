# Calculate the (observed oral) clearance

Calculate the (observed oral) clearance

## Usage

``` r
pk.calc.cl(dose, auc)
```

## Arguments

- dose:

  the dose administered

- auc:

  The area under the concentration-time curve.

## Value

the numeric value of the total (CL) or observed oral clearance (CL/F)

## Details

cl is `dose/auc`.

If `dose` is the same length as the other inputs, then the output will
be the same length as all of the inputs; the function assumes that you
are calculating for multiple intervals simultaneously. If the inputs
other than `dose` are scalars and `dose` is a vector, then the function
assumes multiple doses were given in a single interval, and the sum of
the `dose`s will be used for the calculation.

## References

Gabrielsson J, Weiner D. "Section 2.5.1 Derivation of clearance."
Pharmacokinetic & Pharmacodynamic Data Analysis: Concepts and
Applications, 4th Edition. Stockholm, Sweden: Swedish Pharmaceutical
Press, 2000. 86-7.
