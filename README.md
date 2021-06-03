FFresearch
================

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)

<style> body {text-align: justify} </style>

Fama/French research data conveniently packaged for consumption by R
users. The data is pulled directly from Kenneth French’s online [data
<<<<<<< HEAD
library](http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html).  
=======
library](http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html).
>>>>>>> 6ca7ff92d4d6a00d698ab3dcc627c6ea68e5c26a
Install from [github](https://github.com/bautheac/FFresearch/) with
`devtools::install_github("bautheac/FFresearch")`.

### Portfolios

#### Univariate

The ‘portfolios\_univariate’ dataset provides various feature time
series for Fama/French portfolios formed on single variable sorts.
Sorting variables include size, book-to-market, operating profitability
and investment:

    #>    region frequency         sort variable dividend weights portfolio  field
    #> 1:     US       day market capitalization        Y   value     Dec 2 return
    #> 2:     US       day market capitalization        Y   value     Dec 2 return
    #> 3:     US       day market capitalization        Y   value     Dec 2 return
    #> 4:     US       day market capitalization        Y   value     Dec 2 return
    #> 5:     US       day market capitalization        Y   value     Dec 2 return
    #> 6:     US       day market capitalization        Y   value     Dec 2 return
    #>      period value
    #> 1: 19710104 -0.29
    #> 2: 19710105  1.65
    #> 3: 19710106  1.37
    #> 4: 19710107  0.11
    #> 5: 19710108 -0.19
    #> 6: 19710111  0.47

#### Bivariate

The ‘portfolios\_bivariate’ dataset provides various feature time series
for Fama/French portfolios formed on two variable sorts. Sorting
variables include size, book-to-market, operating profitability and
investment. Size concerns limit the data history to the last ten years;
the full time series are available from the author upon request.

    #>    region frequency       sort variable 1 sort variable 2 dividend weights
    #> 1:     US       day market capitalization     book/market        Y   value
    #> 2:     US       day market capitalization     book/market        Y   value
    #> 3:     US       day market capitalization     book/market        Y   value
    #> 4:     US       day market capitalization     book/market        Y   value
    #> 5:     US       day market capitalization     book/market        Y   value
    #> 6:     US       day market capitalization     book/market        Y   value
    #>    portfolio  field   period value
    #> 1:  BIG HiBM return 20110103  4.81
    #> 2:  BIG HiBM return 20110104  0.16
    #> 3:  BIG HiBM return 20110105  1.80
    #> 4:  BIG HiBM return 20110106 -0.40
    #> 5:  BIG HiBM return 20110107 -0.71
    #> 6:  BIG HiBM return 20110110  0.23

#### Trivariate

The ‘portfolios\_trivariate’ dataset provides various feature time
series for Fama/French portfolios formed on three variable sorts.
Sorting variables include size, book-to-market, operating profitability
and investment:

    #>    region frequency       sort variable 1 sort variable 2
    #> 1:     US     month market capitalization     book/market
    #> 2:     US     month market capitalization     book/market
    #> 3:     US     month market capitalization     book/market
    #> 4:     US     month market capitalization     book/market
    #> 5:     US     month market capitalization     book/market
    #> 6:     US     month market capitalization     book/market
    #>            sort variable 3 dividend weights     portfolio  field period   value
    #> 1: operating profitability        Y   value BIG HiBM.HiOP return 197101 18.7986
    #> 2: operating profitability        Y   value BIG HiBM.HiOP return 197102  4.1366
    #> 3: operating profitability        Y   value BIG HiBM.HiOP return 197103  0.6142
    #> 4: operating profitability        Y   value BIG HiBM.HiOP return 197104  0.9330
    #> 5: operating profitability        Y   value BIG HiBM.HiOP return 197105  2.6881
    #> 6: operating profitability        Y   value BIG HiBM.HiOP return 197106  0.7549

#### Industries

The ‘portfolios\_industries’ dataset provides various feature time
series for Fama/French industry portfolios (Fama and French 1997):

    #>    region frequency dividend weights portfolio  field period value
    #> 1:     US     month        Y   value      Aero return 197101 20.39
    #> 2:     US     month        Y   value      Aero return 197102  4.36
    #> 3:     US     month        Y   value      Aero return 197103  2.49
    #> 4:     US     month        Y   value      Aero return 197104  6.54
    #> 5:     US     month        Y   value      Aero return 197105 -4.19
    #> 6:     US     month        Y   value      Aero return 197106 -1.92

### Factors

The ‘factors’ dataset provides the return (factors) and level (risk free
rate) time series for the classic Fama/French asset pricing factors as
used in their three (Fama and French 1992, 1993, 1995) and most recently
five-factor (Fama and French 2015, 2016, 2017) asset pricing models
extremely popular to the asset pricing enthusiasts:

    #>    region frequency factor period value
    #> 1:     US     month    CMA 197101 -0.14
    #> 2:     US     month    CMA 197102 -0.72
    #> 3:     US     month    CMA 197103 -2.69
    #> 4:     US     month    CMA 197104  0.72
    #> 5:     US     month    CMA 197105  0.30
    #> 6:     US     month    CMA 197106 -1.74

### Variables

The ‘variables’ dataset is a helper dataset that provides details,
including construction methods, for the variables used to construct the
portfolios and asset pricing factors above:

    #> # A tibble: 6 x 3
    #>   name              symbol description                                          
    #>   <chr>             <chr>  <chr>                                                
    #> 1 market capitaliz… ME     Market equity (size) is price times shares outstandi…
    #> 2 book value        BE     Book equity is constructed from Compustat data or co…
    #> 3 book/market       ME/BE  The book-to-market ratio used to form portfolios in …
    #> 4 operating profit… OP     The operating profitability ratio used to form portf…
    #> 5 investment        INV    The investment ratio used to form portfolios in June…
    #> 6 earnings/price    E/P    Earnings is total earnings before extraordinary item…

### Breakpoints

The ‘breakpoints’ dataset is a helper dataset that provides the times
series for the variables breakpoints used to construct the variables
that in turn allow the construction of the portfolios and asset pricing
factors above-mentioned:

    #>    variable frequency percentile period   value
    #> 1:     size     month # positive 202104 1142.00
    #> 2:     size     month         5% 202104  191.41
    #> 3:     size     month        10% 202104  469.18
    #> 4:     size     month        15% 202104  689.71
    #> 5:     size     month        20% 202104 1035.99
    #> 6:     size     month        25% 202104 1466.86

## References

<div id="refs" class="references">

<div id="ref-fama_cross_section_1992">

Fama, Eugene F., and Kenneth R. French. 1992. “The Cross-Section of
Expected Stock Returns.” *The Journal of Finance* 47 (2): 427–65.
<https://doi.org/10.1111/j.1540-6261.1992.tb04398.x>.

</div>

<div id="ref-fama_common_1993">

———. 1993. “Common Risk Factors in the Returns on Stocks and Bonds.”
*Journal of Financial Economics* 33 (1): 3–56.
<https://doi.org/10.1016/0304-405X(93)90023-5>.

</div>

<div id="ref-fama_size_1995">

———. 1995. “Size and Book-to-Market Factors in Earnings and Returns.”
*The Journal of Finance* 50 (1): 131–55.
<https://doi.org/10.1111/j.1540-6261.1995.tb05169.x>.

</div>

<div id="ref-fama_industry_1997">

———. 1997. “Industry Costs of Equity.” *Journal of Financial Economics*
43 (2): 153–93. <https://doi.org/10.1016/S0304-405X(96)00896-3>.

</div>

<div id="ref-fama_five_factor_2015">

———. 2015. “A Five-Factor Asset Pricing Model.” *Journal of Financial
Economics* 116 (1): 1–22.
<https://doi.org/10.1016/j.jfineco.2014.10.010>.

</div>

<div id="ref-fama_dissecting_2016">

———. 2016. “Dissecting Anomalies with a Five-Factor Model.” *The Review
of Financial Studies* 29 (1): 69–103.
<https://doi.org/10.1093/rfs/hhv043>.

</div>

<div id="ref-fama_international_2017">

———. 2017. “International Tests of a Five-Factor Asset Pricing Model.”
*Journal of Financial Economics* 123 (3): 441–63.
<https://doi.org/10.1016/j.jfineco.2016.11.004>.

</div>

</div>
