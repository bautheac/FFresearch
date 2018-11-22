FFresearch
================

[![Travis-CI Build
Status](https://travis-ci.org/bautheac/FFresearch.svg?branch=master)](https://travis-ci.org/bautheac/FFresearch)
[![AppVeyor Build
Status](https://ci.appveyor.com/api/projects/status/github/bautheac/FFresearch?branch=master&svg=true)](https://ci.appveyor.com/project/bautheac/FFresearch)
[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)

<style> body {text-align: justify} </style>

## FFresearch

Fama/French research data conveniently packaged for consumption by R
users. The data is pulled directly from Kenneth French’s online [data
library](http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html).
Size concerns limit the data history to the last ten years; the full
time series are available from the author upon request. Install from
[github](https://github.com/bautheac/FFresearch/) with
`devtools::install_github("bautheac/FFresearch")`.

### portfolios

#### univariate

The ‘portfolios\_univariate’ dataset provides various feature time
series for Fama/French portfolios formed on single variable sorts.
Sorting variables include size, book-to-market, operating profitability
and
    investment:

    #>    region frequency         sort variable dividend weights portfolio
    #> 1:     US       day market capitalization        Y   value     Dec 2
    #> 2:     US       day market capitalization        Y   value     Dec 2
    #> 3:     US       day market capitalization        Y   value     Dec 2
    #> 4:     US       day market capitalization        Y   value     Dec 2
    #> 5:     US       day market capitalization        Y   value     Dec 2
    #> 6:     US       day market capitalization        Y   value     Dec 2
    #>     field   period value
    #> 1: return 20080102 -1.90
    #> 2: return 20080103 -1.34
    #> 3: return 20080104 -3.57
    #> 4: return 20080107  0.65
    #> 5: return 20080108 -2.69
    #> 6: return 20080109  0.99

#### bivariate

The ‘portfolios\_bivariate’ dataset provides various feature time series
for Fama/French portfolios formed on two variable sorts. Sorting
variables include size, book-to-market, operating profitability and
investment:

    #>    region frequency       sort variable 1 sort variable 2 dividend weights
    #> 1:     US       day market capitalization     book/market        Y   value
    #> 2:     US       day market capitalization     book/market        Y   value
    #> 3:     US       day market capitalization     book/market        Y   value
    #> 4:     US       day market capitalization     book/market        Y   value
    #> 5:     US       day market capitalization     book/market        Y   value
    #> 6:     US       day market capitalization     book/market        Y   value
    #>    portfolio  field   period value
    #> 1:  BIG HiBM return 20080102 -1.49
    #> 2:  BIG HiBM return 20080102 -1.50
    #> 3:  BIG HiBM return 20080102 -1.45
    #> 4:  BIG HiBM return 20080103 -0.27
    #> 5:  BIG HiBM return 20080103 -0.06
    #> 6:  BIG HiBM return 20080103  0.42

#### trivariate

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
    #>            sort variable 3 dividend weights     portfolio  field period
    #> 1: operating profitability        Y   value BIG HiBM.HiOP return 200801
    #> 2: operating profitability        Y   value BIG HiBM.HiOP return 200801
    #> 3: operating profitability        Y   value BIG HiBM.HiOP return 200801
    #> 4: operating profitability        Y   value BIG HiBM.HiOP return 200801
    #> 5: operating profitability        Y   value BIG HiBM.HiOP return 200801
    #> 6: operating profitability        Y   value BIG HiBM.HiOP return 200801
    #>       value
    #> 1: -11.1612
    #> 2: -11.1612
    #> 3: -11.1612
    #> 4: -11.1612
    #> 5: -11.1612
    #> 6: -11.1612

#### industries

The ‘portfolios\_industries’ dataset provides various feature time
series for Fama/French industry portfolios (Fama and French
    1997):

    #>    region frequency dividend weights portfolio  field period value
    #> 1:     US     month        Y   value      Aero return 200801 -7.01
    #> 2:     US     month        Y   value      Aero return 200801 -7.01
    #> 3:     US     month        Y   value      Aero return 200801 -7.01
    #> 4:     US     month        Y   value      Aero return 200801 -7.01
    #> 5:     US     month        Y   value      Aero return 200801 -7.01
    #> 6:     US     month        Y   value      Aero return 200801 -7.01

### factors

The ‘factors’ dataset provides the return (factors) and level (risk free
rate) time series for the classic Fama/French asset pricing factors as
used in their three (Fama and French 1992, 1993, 1995) and most recently
five-factor (Fama and French 2015, 2016, 2017) asset pricing models
extremely popular to the asset pricing enthousiasts:

    #>    region frequency factor period value
    #> 1:     US     month    CMA 200801  2.20
    #> 2:     US     month    CMA 200802 -1.07
    #> 3:     US     month    CMA 200803  0.47
    #> 4:     US     month    CMA 200804 -2.56
    #> 5:     US     month    CMA 200805  0.04
    #> 6:     US     month    CMA 200806 -0.42

### variables

The ‘variables’ dataset is a helper dataset that provides details,
including contruction methods, for the variables used to construct the
portfolios and asset pricing factors above:

    #> # A tibble: 6 x 3
    #>   name             symbol description                                     
    #>   <chr>            <chr>  <chr>                                           
    #> 1 market capitali~ ME     Market equity (size) is price times shares outs~
    #> 2 book value       BE     Book equity is constructed from Compustat data ~
    #> 3 book/market      ME/BE  The book-to-market ratio used to form portfolio~
    #> 4 operating profi~ OP     The operating profitability ratio used to form ~
    #> 5 investment       INV    The investment ratio used to form portfolios in~
    #> 6 earnings/price   E/P    Earnings is total earnings before extraordinary~

### breakpoints

The ‘breakpoints’ dataset is a helper dataset that provides the times
series for the variables breakpoints used to construct the variables
that in turn allow the construction of the portfolios and asset pricing
factors above-mentioned:

    #>    variable frequency percentile period value
    #> 1:     size     month # positive 200801  1347
    #> 2:     size     month # positive 200802  1346
    #> 3:     size     month # positive 200803  1346
    #> 4:     size     month # positive 200804  1346
    #> 5:     size     month # positive 200805  1349
    #> 6:     size     month # positive 200806  1348

## references

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
