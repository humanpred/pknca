# Calculate the absolute (or relative) bioavailability

Calculate the absolute (or relative) bioavailability

## Usage

``` r
pk.calc.f(dose1, auc1, dose2, auc2)
```

## Arguments

- dose1:

  The dose administered in route or method 1

- auc1:

  The AUC from 0 to infinity or 0 to tau administered in route or method
  1

- dose2:

  The dose administered in route or method 2

- auc2:

  The AUC from 0 to infinity or 0 to tau administered in route or method
  2

## Details

f is `(auc2/dose2)/(auc1/dose1)`.
